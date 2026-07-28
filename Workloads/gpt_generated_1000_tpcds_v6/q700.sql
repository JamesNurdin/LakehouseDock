/*
Goal: Produce a daily store‑level sales performance view that combines catalog, web and store sales, flags high‑profit stores, ranks stores by total profit, and only includes stores with inventory activity. The query joins all 14 selected TPC‑DS tables using the permitted join keys, applies several filters, uses a scalar sub‑query, a CASE expression and a window rank, and returns the top 100 ranked stores.
*/
WITH base AS (
    SELECT
        d.d_date,
        s.s_store_id,
        ss.ss_item_sk,
        ss.ss_net_paid                             AS ss_net_paid,
        ws.ws_net_paid                             AS ws_net_paid,
        cs.cs_net_paid                             AS cs_net_paid,
        ss.ss_net_profit                           AS ss_net_profit,
        (
            SELECT COUNT(*)
            FROM inventory i2
            WHERE i2.inv_item_sk = ss.ss_item_sk
        )                                          AS inv_item_cnt
    FROM date_dim d
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN store_sales ss   ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s          ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                           AND sr.sr_ticket_number = ss.ss_ticket_number
                           AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r         ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws    ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we      ON ws.ws_web_site_sk = we.web_site_sk
    JOIN web_returns wr  ON wr.wr_returned_date_sk = d.d_date_sk
                           AND wr.wr_order_number = ws.ws_order_number
                           AND wr.wr_item_sk = ws.ws_item_sk
    JOIN inventory i      ON i.inv_date_sk = d.d_date_sk
    JOIN customer c       ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE d.d_year = 2001
      AND ca.ca_country = 'United States'
      AND c.c_birth_country = 'SWITZERLAND'
      AND s.s_state = 'CA'
      AND we.web_tax_percentage > 0.05
),
agg AS (
    SELECT
        d_date,
        s_store_id,
        SUM(ss_net_paid)                           AS store_sales_net,
        SUM(ws_net_paid)                           AS web_sales_net,
        SUM(cs_net_paid)                           AS catalog_sales_net,
        SUM(ss_net_profit)                         AS total_store_profit,
        CASE WHEN SUM(ss_net_profit) > 10000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_category,
        MAX(inv_item_cnt)                          AS max_inv_item_cnt
    FROM base
    GROUP BY d_date, s_store_id
)
SELECT
    d_date,
    s_store_id,
    store_sales_net,
    web_sales_net,
    catalog_sales_net,
    total_store_profit,
    profit_category,
    RANK() OVER (ORDER BY total_store_profit DESC) AS profit_rank
FROM agg
WHERE max_inv_item_cnt > 100
ORDER BY profit_rank
LIMIT 100
