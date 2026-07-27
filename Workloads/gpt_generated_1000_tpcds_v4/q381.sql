WITH cs AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 1
      AND cs.cs_ext_sales_price > 100
      AND cs.cs_net_profit > 0
),
sr AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_store_sk,
        sr.sr_return_amt,
        sr.sr_fee,
        sr.sr_return_ship_cost,
        sr.sr_net_loss
    FROM store_returns sr
    WHERE sr.sr_return_amt > 50
      AND sr.sr_fee > 10
      AND sr.sr_return_ship_cost >= 0
)
SELECT
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    i.i_item_desc,
    p.p_promo_name,
    hd.hd_vehicle_count,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(sr.sr_return_amt) AS total_returns,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Positive' ELSE 'Non-Positive' END AS profit_indicator
FROM cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN sr ON sr.sr_returned_date_sk = d.d_date_sk
           AND sr.sr_item_sk = i.i_item_sk
LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
WHERE d.d_year BETWEEN 1999 AND 2001
  AND t.t_hour BETWEEN 8 AND 20
  AND i.i_brand = 'Brand#12'
  AND p.p_channel_email = 'N'
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    i.i_item_desc,
    p.p_promo_name,
    hd.hd_vehicle_count
ORDER BY total_profit DESC
LIMIT 100
