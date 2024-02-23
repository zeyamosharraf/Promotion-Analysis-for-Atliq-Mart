--Q_1) Provide a list of products with a base price greater than 500 and that are featured in promo type of "BOGOF" (Buy One Get One free).
--This information will help us identify high-value products that are currently being heavily discounted, which can be useful for evaluating our pricing and promotion strategies.

SELECT
    dp.product_name
FROM
    dim_products dp
    JOIN fact_events fe ON dp.product_code = fe.product_code
WHERE
    fe.base_price > 500
    AND fe.promo_type = 'BOGOF'
Group by dp.product_name;

--Q_2) Generate a report that provides an overview of the number of stores in each city. The result will be sorted in descending order of store counts, allowing us to identify the cities with the highest store presence.
-- The report includes two essentail fields: City and store count, which will assist in optimizing our retial operations.

SELECT
    city,
    COUNT(DISTINCT store_id) AS store_count
FROM
    dim_stores
GROUP BY
    city
ORDER BY
    store_count DESC;
	


---- ** ADDING COLUMN ** ----

-- Make a new column to change the base price for after promotion
ALTER TABLE fact_events
ADD COLUMN promo_price DECIMAL(10);

UPDATE fact_events
SET promo_price = CASE
    WHEN promo_type = 'BOGOF' THEN base_price * 0.5
	WHEN promo_type = '500 Cashback' THEN base_price - 500
	WHEN promo_type = '33% OFF' THEN base_price * 0.67
	WHEN promo_type = '25% OFF' THEN base_price * 0.75
	WHEN promo_type = '50% OFF' THEN base_price * 0.5
    ELSE base_price
END;

-- Make a new column to change the quantity sold after promo to adjust sold after promo multiply by 2 for "BOGOF"

ALTER TABLE fact_events
ADD COLUMN adjusted_sold_after_promo DECIMAL(10);

UPDATE fact_events
SET adjusted_sold_after_promo = CASE
    WHEN promo_type = 'BOGOF' THEN quantity_sold_after_promo * 2
    ELSE quantity_sold_after_promo
END;

--- ** ADD COLUMN ** --

-- Q_3) Generate a report that displays each campaign along with the total revenue generated before and after the campaign? 
-- The report includes three key fields: campaign_name, total_revenue(before_promotion), total_Revenue(After_promotion). 
-- This report should help in evaluating the financial impact of out promotional campaigns. 
-- (Display the values in millions)

SELECT
    dc.campaign_name,
    CONCAT(CAST(SUM(fe.base_price * fe.quantity_sold_before_promo) / 1000000 AS DECIMAL(10)), 'M') AS total_revenue_before_promo,
    CONCAT(CAST(SUM(fe.promo_price * fe.adjusted_sold_after_promo) / 1000000 AS DECIMAL(10, 2)), 'M') AS total_revenue_after_promo
FROM
    fact_events fe
    JOIN dim_campaigns dc ON fe.campaign_id = dc.campaign_id
GROUP BY
    dc.campaign_name;
	

-- Q_4) User Produce a report that calculates the Incremental sold quantity(ISU %) for each category during the Diwali campaign. 
-- Additionally, provide rankings for the categories based on their ISU%.
-- The report will include three key fields: category, ISU% and rank order. 
-- This information will assist in assessing the category-wise success and impact of the diwali campaign on incremental sales.	
	
SELECT
    dp.category,
    CONCAT(CAST(((SUM(fe.adjusted_sold_after_promo) - SUM(fe.quantity_sold_before_promo))/SUM(fe.quantity_sold_before_promo))*100 AS DECIMAL(10, 2)), '%') as ISU,
    RANK() OVER (ORDER BY ((SUM(fe.adjusted_sold_after_promo) - SUM(fe.quantity_sold_before_promo))/SUM(fe.quantity_sold_before_promo)) DESC) as rank_order
FROM
    fact_events fe
    JOIN dim_products dp ON fe.product_code = dp.product_code
    JOIN dim_campaigns dc ON fe.campaign_id = dc.campaign_id
WHERE
    dc.campaign_name = 'Diwali'
GROUP BY
    dp.category;	
	

-- Q_5) Create a report featuring the Top 5 products, ranked by incremental revenue percentage(IR%), across all campaigns.
-- The report will provede essentail information including product name, category, and IR%.
-- This analysis helps identify the most successful products in terms of incremental revenue across our campaigns, assisting in product optimization.


SELECT
    dp.product_name, dp.category,
    CONCAT(CAST(((SUM(fe.promo_price * fe.adjusted_sold_after_promo) - SUM(fe.base_price * fe.quantity_sold_before_promo))/SUM(fe.base_price * fe.quantity_sold_before_promo))*100 AS DECIMAL(10, 2)), '%') as IR,
    RANK() OVER (ORDER BY ((SUM(fe.promo_price * fe.adjusted_sold_after_promo) - SUM(fe.base_price * fe.quantity_sold_before_promo))/SUM(fe.base_price * fe.quantity_sold_before_promo)) DESC) as rank_order
FROM
    fact_events fe
    JOIN dim_products dp ON fe.product_code = dp.product_code
GROUP BY
    dp.product_name, dp.category
Limit 5;
