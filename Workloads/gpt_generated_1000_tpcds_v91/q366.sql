WITH unsold_items AS (
    SELECT i_item_sk
    FROM item
    WHERE i_category = 'Electronics'
    EXCEPT
    SELECT DISTINCT cs_item_sk
    FROM catalog_sales
),
sales_agg AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_item_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_wholesale_cost,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        cs.cs_coupon_amt,
        d_sold.d_year,
        d_sold.d_fy_quarter_seq,
        hd_bill.hd_income_band_sk,
        hd_ship.hd_vehicle_count AS ship_vehicle_count,
        i.i_category,
        i.i_brand,
        ws.web_site_sk,
        ws.web_street_type,
        ws.web_gmt_offset
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_current_week = 'N'
      AND d_sold.d_fy_quarter_seq >= 6
      AND cs.cs_wholesale_cost > 35
      AND cs.cs_coupon_amt < 1500
      AND hd_bill.hd_income_band_sk IN (10, 15)
      AND ws.web_street_type = 'Avenue'
      AND ws.web_gmt_offset BETWEEN -5 AND 5
)
SELECT
    sa.d_year,
    sa.i_category,
    sa.i_brand,
    sa.web_street_type,
    sa.cs_net_profit,
    CASE WHEN sa.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY sa.d_year, sa.i_category ORDER BY sa.cs_net_profit DESC) AS rn,
    daily_sales.daily_total,
    (SELECT AVG(cs_sub.cs_ext_discount_amt) FROM catalog_sales cs_sub WHERE cs_sub.cs_item_sk = sa.cs_item_sk) AS avg_discount_for_item,
    (SELECT COUNT(*) FROM unsold_items ui WHERE ui.i_item_sk = sa.cs_item_sk) AS unsold_flag,
    sa.ship_vehicle_count
FROM sales_agg sa
CROSS JOIN LATERAL (
    SELECT SUM(cs3.cs_ext_sales_price) AS daily_total
    FROM catalog_sales cs3
    WHERE cs3.cs_item_sk = sa.cs_item_sk
      AND cs3.cs_sold_date_sk = sa.cs_sold_date_sk
) AS daily_sales
WHERE NOT EXISTS (SELECT 1 FROM unsold_items ui WHERE ui.i_item_sk = sa.cs_item_sk)
ORDER BY profit_flag DESC, rn
