WITH sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        sm.sm_type AS ship_type,
        d_sold.d_year AS year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d_sold.d_year = 2001
      AND d_sold.d_moy = 5
      AND sm.sm_type = 'AIR'
      AND cs.cs_net_profit > 1000
    GROUP BY cs.cs_bill_customer_sk, sm.sm_type, d_sold.d_year
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    sa.year,
    sa.ship_type,
    sa.total_sales,
    sa.total_profit,
    sa.sales_cnt,
    d_ws.d_month_seq,
    wsite.web_name,
    inv.inv_quantity_on_hand,
    (
        SELECT AVG(inv2.inv_quantity_on_hand)
        FROM inventory inv2
        WHERE inv2.inv_date_sk = d_sr.d_date_sk
    ) AS avg_inv_qty_by_date,
    sr.sr_return_amt,
    ws.ws_ext_ship_cost
FROM sales_agg sa
JOIN customer c
    ON sa.customer_sk = c.c_customer_sk
JOIN web_sales ws
    ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN date_dim d_ws
    ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN store_returns sr
    ON c.c_customer_sk = sr.sr_customer_sk
JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_sr.d_date_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND d_ws.d_weekend = 'N'
  AND wsite.web_country = 'United States'
  AND inv.inv_quantity_on_hand > 800
  AND sr.sr_fee > 50
  AND ws.ws_ext_ship_cost < 50
ORDER BY sa.total_sales DESC
LIMIT 100
