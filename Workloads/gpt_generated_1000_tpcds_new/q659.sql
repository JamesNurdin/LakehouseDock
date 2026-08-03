WITH inv_agg AS (
    SELECT
        d.d_date_sk,
        w.w_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_date
    FROM date_dim d
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY d.d_date_sk, w.w_warehouse_sk
)
SELECT
    d.d_year,
    s.s_state,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_store_customers,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_web_bill_customers,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    AVG(ss.ss_net_profit) AS avg_store_profit,
    MAX(ws.ws_net_profit) AS max_web_profit,
    inv_agg.total_qty_on_date,
    w.w_warehouse_name
FROM date_dim d
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_hdemo_sk = hd.hd_demo_sk
    AND sr.sr_store_sk = s.s_store_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN inv_agg ON inv_agg.d_date_sk = d.d_date_sk AND inv_agg.w_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year = 2002
  AND s.s_state = 'CA'
  AND ib.ib_upper_bound <= 100000
  AND ws.ws_quantity > 2
  AND web.web_mkt_id = 3
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_ticket_number = ss.ss_ticket_number
          AND sr2.sr_net_loss > 0
    )
GROUP BY
    d.d_year,
    s.s_state,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    inv_agg.total_qty_on_date,
    w.w_warehouse_name
HAVING COUNT(*) > 10
ORDER BY total_store_sales DESC
LIMIT 100
