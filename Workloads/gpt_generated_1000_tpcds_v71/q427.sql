WITH avg_profit AS (
    SELECT AVG(cs2.cs_net_profit) AS val
    FROM catalog_sales cs2
)
SELECT DISTINCT
    c.c_customer_id,
    ca.ca_state,
    d_cs.d_date,
    i.i_brand,
    i.i_category,
    hd.hd_vehicle_count,
    ib.ib_upper_bound,
    cs.cs_quantity,
    cs.cs_net_paid,
    ws.ws_quantity AS ws_quantity,
    ws.ws_net_paid_inc_ship_tax,
    web.web_name,
    sr.sr_return_amt,
    t_ret.t_hour,
    CASE
        WHEN cs.cs_net_profit > (SELECT val FROM avg_profit) THEN 'Above'
        ELSE 'Below'
    END AS profit_category,
    SUM(cs.cs_net_paid) OVER (
        PARTITION BY c.c_customer_sk
        ORDER BY d_cs.d_date
        ROWS UNBOUNDED PRECEDING
    ) AS running_total_paid,
    RANK() OVER (
        PARTITION BY c.c_customer_sk
        ORDER BY cs.cs_net_paid DESC
    ) AS profit_rank
FROM catalog_sales cs
JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN web_sales ws ON cs.cs_sold_date_sk = ws.ws_sold_date_sk
    AND cs.cs_item_sk = ws.ws_item_sk
JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
WHERE d_cs.d_year = 2000
  AND i.i_current_price > 50
  AND hd.hd_vehicle_count >= 2
  AND ib.ib_upper_bound <= 50000
  AND p.p_discount_active = 'Y'
  AND ws.ws_quantity > 5
  AND web.web_state = 'CA'
ORDER BY c.c_customer_id, d_cs.d_date DESC
LIMIT 100
