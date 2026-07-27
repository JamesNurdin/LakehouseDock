WITH cs_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_promo_sk,
        SUM(cs.cs_net_paid) AS total_cs_net_paid,
        SUM(cs.cs_quantity) AS total_cs_quantity
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IS NOT NULL
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk, cs.cs_sold_time_sk, cs.cs_promo_sk
)

SELECT
    d.d_year,
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    SUM(cs_agg.total_cs_net_paid) AS catalog_net_paid,
    SUM(ws.ws_net_paid) AS web_net_paid,
    SUM(sr.sr_return_amt) AS store_return_amt,
    SUM(wr.wr_return_amt) AS web_return_amt,
    SUM(inv.inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT cd.cd_demo_sk) AS distinct_customer_demo_cnt
FROM cs_agg
JOIN catalog_sales cs_orig
  ON cs_orig.cs_item_sk = cs_agg.cs_item_sk
  AND cs_orig.cs_sold_date_sk = cs_agg.cs_sold_date_sk
  AND cs_orig.cs_sold_time_sk = cs_agg.cs_sold_time_sk
  AND cs_orig.cs_promo_sk = cs_agg.cs_promo_sk
JOIN date_dim d
  ON d.d_date_sk = cs_agg.cs_sold_date_sk
JOIN time_dim t_cs
  ON t_cs.t_time_sk = cs_agg.cs_sold_time_sk
JOIN item i
  ON i.i_item_sk = cs_agg.cs_item_sk
JOIN promotion p
  ON p.p_promo_sk = cs_agg.cs_promo_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
  AND ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t_ws
  ON t_ws.t_time_sk = ws.ws_sold_time_sk
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
  AND sr.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t_sr
  ON t_sr.t_time_sk = sr.sr_return_time_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
  AND wr.wr_returned_date_sk = d.d_date_sk
  AND wr.wr_order_number = ws.ws_order_number
JOIN time_dim t_wr
  ON t_wr.t_time_sk = wr.wr_returned_time_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
  AND inv.inv_date_sk = d.d_date_sk
JOIN customer_demographics cd
  ON cd.cd_demo_sk = cs_orig.cs_bill_cdemo_sk
WHERE d.d_fy_quarter_seq = 8
  AND i.i_brand = 'Brand#1'
  AND inv.inv_quantity_on_hand > 1000
  AND t_cs.t_am_pm = 'PM'
GROUP BY d.d_year, i.i_item_id, i.i_product_name, p.p_promo_name
HAVING SUM(cs_agg.total_cs_net_paid) > 10000
ORDER BY d.d_year DESC, catalog_net_paid DESC
LIMIT 100
