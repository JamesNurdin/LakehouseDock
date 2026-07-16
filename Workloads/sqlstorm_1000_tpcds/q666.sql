WITH sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           CAST(NULL AS integer) AS store_sk,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_quantity AS quantity
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_store_sk,
           ss.ss_net_paid,
           ss.ss_net_profit,
           ss.ss_quantity
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           CAST(NULL AS integer) AS store_sk,
           ws.ws_net_paid,
           ws.ws_net_profit,
           ws.ws_quantity
    FROM web_sales ws
),
returns AS (
    SELECT cr.cr_returned_date_sk AS date_sk,
           cr.cr_item_sk AS item_sk,
           cr.cr_return_quantity AS return_qty,
           cr.cr_return_amount AS return_amt
    FROM catalog_returns cr
    UNION ALL
    SELECT sr.sr_returned_date_sk,
           sr.sr_item_sk,
           sr.sr_return_quantity,
           sr.sr_return_amt
    FROM store_returns sr
    UNION ALL
    SELECT wr.wr_returned_date_sk,
           wr.wr_item_sk,
           wr.wr_return_quantity,
           wr.wr_return_amt
    FROM web_returns wr
)
SELECT d.d_year,
       i.i_category,
       st.s_state,
       SUM(s.net_paid) AS total_net_paid,
       SUM(s.net_profit) AS total_net_profit,
       COALESCE(SUM(r.return_amt), 0) AS total_return_amount,
       COALESCE(SUM(r.return_qty), 0) AS total_return_qty,
       SUM(s.net_paid) - COALESCE(SUM(r.return_amt), 0) AS net_paid_minus_returns,
       CASE WHEN SUM(s.quantity) = 0 THEN 0
            ELSE COALESCE(SUM(r.return_qty), 0) / CAST(SUM(s.quantity) AS double)
       END AS return_rate
FROM sales s
LEFT JOIN returns r
    ON s.date_sk = r.date_sk AND s.item_sk = r.item_sk
JOIN date_dim d
    ON s.date_sk = d.d_date_sk
JOIN item i
    ON s.item_sk = i.i_item_sk
LEFT JOIN store st
    ON s.store_sk = st.s_store_sk
GROUP BY d.d_year, i.i_category, st.s_state
ORDER BY d.d_year DESC, total_net_profit DESC
LIMIT 100
