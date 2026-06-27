WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_name,
        i.i_category,
        i.i_category_id,
        ca.ca_state,
        cd.cd_gender,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY ss.ss_store_sk, s.s_store_name, i.i_category, i.i_category_id, ca.ca_state, cd.cd_gender
),
returns_agg AS (
    SELECT
        sr.sr_store_sk,
        s.s_store_name,
        i.i_category,
        i.i_category_id,
        ca.ca_state,
        cd.cd_gender,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    GROUP BY sr.sr_store_sk, s.s_store_name, i.i_category, i.i_category_id, ca.ca_state, cd.cd_gender
)
SELECT
    sa.s_store_name,
    sa.ca_state,
    sa.cd_gender,
    sa.i_category,
    sa.total_sales,
    COALESCE(ra.total_return_amount, 0) AS total_return_amount,
    sa.total_net_profit - COALESCE(ra.total_net_loss, 0) AS net_profit_after_returns,
    ROUND(CASE WHEN sa.sales_transactions > 0 THEN sa.total_discount / sa.sales_transactions ELSE 0 END, 2) AS avg_discount_per_txn,
    ROUND(CASE WHEN sa.total_sales > 0 THEN COALESCE(ra.total_return_amount, 0) / sa.total_sales ELSE 0 END, 4) AS return_rate,
    COALESCE(ra.return_transactions, 0) AS return_transactions
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.ss_store_sk = ra.sr_store_sk
    AND sa.i_category_id = ra.i_category_id
    AND sa.ca_state = ra.ca_state
    AND sa.cd_gender = ra.cd_gender
ORDER BY net_profit_after_returns DESC
LIMIT 100
