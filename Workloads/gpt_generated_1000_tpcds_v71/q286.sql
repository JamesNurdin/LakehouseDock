/*
Goal: Calculate profit and loss metrics broken down by item category, customer state and a price tier (high/low).
The query joins all twelve TPC‑DS tables using only the allowed join keys, aggregates the detailed rows in a CTE,
then rolls up the results with a ROLLUP to get hierarchical totals. It also applies three filter predicates, a CASE expression,
and includes a scalar sub‑query that returns the overall average catalog profit.
*/
WITH base AS (
    SELECT
        i.i_category AS i_category,
        ca.ca_state AS ca_state,
        CASE WHEN cs.cs_sales_price > 1000 THEN 'High' ELSE 'Low' END AS price_category,
        ss.ss_net_profit AS store_net_profit,
        cs.cs_net_profit AS catalog_net_profit,
        ws.ws_net_profit AS web_net_profit,
        sr.sr_net_loss AS store_return_loss,
        wr.wr_net_loss AS web_return_loss
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    WHERE i.i_category = 'Electronics'
      AND w.w_warehouse_sq_ft > 500000
      AND ca.ca_state = 'CA'
),
sales_agg AS (
    SELECT
        i_category,
        ca_state,
        price_category,
        SUM(store_net_profit) AS sum_store_profit,
        SUM(catalog_net_profit) AS sum_catalog_profit,
        SUM(web_net_profit) AS sum_web_profit,
        SUM(store_return_loss) AS sum_store_loss,
        SUM(web_return_loss) AS sum_web_return_loss,
        COUNT(*) AS txn_count
    FROM base
    GROUP BY i_category, ca_state, price_category
)
SELECT
    i_category,
    ca_state,
    price_category,
    SUM(sum_store_profit) AS total_store_profit,
    SUM(sum_catalog_profit) AS total_catalog_profit,
    SUM(sum_web_profit) AS total_web_profit,
    SUM(sum_store_loss) AS total_store_loss,
    SUM(sum_web_return_loss) AS total_web_return_loss,
    SUM(txn_count) AS total_txns,
    (SELECT AVG(cs.cs_net_profit) FROM catalog_sales cs) AS avg_catalog_profit_overall
FROM sales_agg
GROUP BY ROLLUP(i_category, ca_state, price_category)
HAVING SUM(sum_store_profit) > 0
ORDER BY total_store_profit DESC
