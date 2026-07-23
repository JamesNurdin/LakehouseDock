WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_quantity,
        cs.cs_ext_discount_amt,
        cs.cs_net_paid,
        cs.cs_item_sk
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_response_target = 1
      AND p.p_channel_event = 'N'
      AND cs.cs_ext_discount_amt > 1000
)
SELECT
    w.w_warehouse_name,
    w.w_state,
    w.w_county,
    d_sold.d_year,
    d_sold.d_month_seq,
    SUM(fs.cs_net_paid) AS total_net_paid,
    SUM(fs.cs_ext_discount_amt) AS total_discount,
    AVG(fs.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT fs.cs_item_sk) AS distinct_items_sold
FROM filtered_sales fs
JOIN date_dim d_sold ON fs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON fs.cs_ship_date_sk = d_ship.d_date_sk
JOIN warehouse w ON fs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON fs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE w.w_state = 'NY'
  AND w.w_county = 'Bronx County'
  AND d_sold.d_year = 1998
GROUP BY w.w_warehouse_name, w.w_state, w.w_county, d_sold.d_year, d_sold.d_month_seq
ORDER BY total_net_paid DESC
LIMIT 100
