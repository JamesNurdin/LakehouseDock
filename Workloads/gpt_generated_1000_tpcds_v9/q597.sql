WITH
store_agg AS (
    SELECT
        i.i_category,
        t.t_hour,
        'store' AS channel,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_return_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        MAX(inv_latest.inv_quantity_on_hand) AS inv_quantity_on_hand
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                              AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    CROSS JOIN LATERAL (
        SELECT inv.inv_quantity_on_hand
        FROM inventory inv
        WHERE inv.inv_item_sk = i.i_item_sk
        ORDER BY inv.inv_quantity_on_hand DESC
        LIMIT 1
    ) AS inv_latest
    GROUP BY i.i_category, t.t_hour
),
web_agg AS (
    SELECT
        i.i_category,
        t.t_hour,
        'web' AS channel,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount,
        COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
        COUNT(DISTINCT ws.ws_order_number) AS num_transactions,
        CAST(NULL AS integer) AS inv_quantity_on_hand
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                              AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    GROUP BY i.i_category, t.t_hour
),
catalog_agg AS (
    SELECT
        i.i_category,
        t.t_hour,
        'catalog' AS channel,
        CAST(0 AS decimal(7,2)) AS total_sales,
        CAST(0 AS decimal(7,2)) AS total_profit,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(DISTINCT cr.cr_order_number) AS num_transactions,
        CAST(NULL AS integer) AS inv_quantity_on_hand
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer cust_refund ON cr.cr_refunded_customer_sk = cust_refund.c_customer_sk
    JOIN customer cust_return ON cr.cr_returning_customer_sk = cust_return.c_customer_sk
    LEFT JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    LEFT JOIN household_demographics hd_return ON cr.cr_returning_hdemo_sk = hd_return.hd_demo_sk
    LEFT JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    LEFT JOIN customer_address ca_return ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    GROUP BY i.i_category, t.t_hour
),
combined AS (
    SELECT i_category, t_hour, channel, total_sales, total_profit, total_return_amount, total_return_loss, num_transactions, inv_quantity_on_hand FROM store_agg
    UNION ALL
    SELECT i_category, t_hour, channel, total_sales, total_profit, total_return_amount, total_return_loss, num_transactions, inv_quantity_on_hand FROM web_agg
    UNION ALL
    SELECT i_category, t_hour, channel, total_sales, total_profit, total_return_amount, total_return_loss, num_transactions, inv_quantity_on_hand FROM catalog_agg
)
SELECT
    i_category,
    t_hour,
    channel,
    total_sales,
    total_profit,
    total_return_amount,
    total_return_loss,
    num_transactions,
    inv_quantity_on_hand,
    RANK() OVER (PARTITION BY channel ORDER BY total_sales DESC) AS sales_rank,
    SUM(total_sales) OVER (PARTITION BY i_category) AS category_total_sales
FROM (
    SELECT
        i_category,
        t_hour,
        channel,
        SUM(total_sales) AS total_sales,
        SUM(total_profit) AS total_profit,
        SUM(total_return_amount) AS total_return_amount,
        SUM(total_return_loss) AS total_return_loss,
        SUM(num_transactions) AS num_transactions,
        MAX(inv_quantity_on_hand) AS inv_quantity_on_hand
    FROM combined
    GROUP BY i_category, t_hour, channel
    HAVING SUM(total_sales) > 1000
) AS agg
ORDER BY total_sales DESC
LIMIT 100
