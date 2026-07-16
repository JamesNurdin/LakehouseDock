WITH d AS (
    SELECT
        d_date_sk,
        d_date,
        d_year,
        d_month_seq,
        d_quarter_seq,
        d_week_seq,
        d_day_name,
        CASE WHEN d_holiday = 'Y' THEN 1 ELSE 0 END AS is_holiday
    FROM date_dim
    WHERE d_year BETWEEN 1998 AND 2000
),
cust_demo AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(cd.cd_dep_count, 0) AS dep_cnt,
        COALESCE(c.c_birth_year, 1900) AS birth_year
    FROM customer c
    LEFT JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
catalog_sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        CASE WHEN cs.cs_quantity > 10 THEN 'BULK' ELSE 'REGULAR' END AS qty_category,
        COALESCE(cr.cr_return_quantity, 0) AS return_qty,
        COALESCE(cr.cr_net_loss, 0) AS net_loss,
        (cs.cs_net_paid - COALESCE(cr.cr_net_loss, 0)) AS net_adj_paid,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY cs.cs_sold_date_sk DESC) AS rn_customer_recent
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_sold_date_sk = cr.cr_returned_date_sk
    WHERE cs.cs_sold_date_sk IS NOT NULL
),
store_sales_agg AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        COALESCE(sr.sr_return_quantity, 0) AS store_return_qty,
        COALESCE(sr.sr_net_loss, 0) AS store_net_loss,
        (ss.ss_net_paid - COALESCE(sr.sr_net_loss, 0)) AS net_adj_paid,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_customer_sk ORDER BY ss.ss_sold_date_sk DESC) AS rn_customer_recent
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_sold_date_sk = sr.sr_returned_date_sk
    WHERE ss.ss_sold_date_sk IS NOT NULL OR sr.sr_returned_date_sk IS NOT NULL
),
web_sales_agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        COALESCE(wr.wr_return_quantity, 0) AS web_return_qty,
        COALESCE(wr.wr_net_loss, 0) AS web_net_loss,
        (ws.ws_net_paid - COALESCE(wr.wr_net_loss, 0)) AS net_adj_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn_customer_recent
    FROM web_sales ws
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_sold_date_sk = wr.wr_returned_date_sk
    WHERE ws.ws_sold_date_sk IS NOT NULL
),
combined AS (
    SELECT
        'CATALOG' AS channel,
        cs.cs_order_number AS order_id,
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.return_qty,
        cs.net_loss,
        cs.net_adj_paid,
        cs.rn_customer_recent
    FROM catalog_sales_agg cs
    UNION ALL
    SELECT
        'STORE' AS channel,
        ss.ss_ticket_number AS order_id,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.store_return_qty AS return_qty,
        ss.store_net_loss AS net_loss,
        ss.net_adj_paid,
        ss.rn_customer_recent
    FROM store_sales_agg ss
    UNION ALL
    SELECT
        'WEB' AS channel,
        ws.ws_order_number AS order_id,
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.web_return_qty AS return_qty,
        ws.web_net_loss AS net_loss,
        ws.net_adj_paid,
        ws.rn_customer_recent
    FROM web_sales_agg ws
),
ranked AS (
    SELECT
        r.channel,
        r.order_id,
        r.date_sk,
        r.customer_sk,
        r.item_sk,
        r.quantity,
        r.net_paid,
        r.net_profit,
        r.return_qty,
        r.net_loss,
        r.net_adj_paid,
        r.rn_customer_recent,
        DENSE_RANK() OVER (PARTITION BY r.channel ORDER BY r.net_adj_paid DESC NULLS LAST) AS net_adj_paid_rank,
        SUM(r.net_adj_paid) OVER (PARTITION BY r.channel ORDER BY r.date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_adj_paid,
        CASE
            WHEN r.net_adj_paid IS NULL THEN 'UNKNOWN'
            WHEN r.net_adj_paid < 0 THEN 'LOSS'
            WHEN r.net_adj_paid = 0 THEN 'BREAKEVEN'
            ELSE 'PROFIT'
        END AS profit_category,
        CONCAT('CUST_', CAST(r.customer_sk AS VARCHAR), '_', COALESCE(CAST(r.date_sk AS VARCHAR), 'NULL')) AS cust_date_key,
        COALESCE(
            (SELECT SUM(c2.net_adj_paid)
             FROM combined c2
             WHERE c2.customer_sk = r.customer_sk
               AND c2.date_sk < r.date_sk),
            0) AS prev_customer_sales
    FROM combined r
),
final AS (
    SELECT
        r.channel,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        r.profit_category,
        COUNT(DISTINCT r.customer_sk) AS distinct_customers,
        SUM(r.quantity) AS total_quantity,
        SUM(r.net_adj_paid) AS total_net_adj_paid,
        AVG(r.net_adj_paid) AS avg_net_adj_paid,
        MAX(r.net_adj_paid) AS max_net_adj_paid,
        MIN(r.net_adj_paid) AS min_net_adj_paid,
        APPROX_PERCENTILE(r.net_adj_paid, 0.5) AS median_net_adj_paid,
        COUNT_IF(r.net_adj_paid < 0) AS loss_transactions,
        COUNT_IF(r.return_qty > 0) AS return_transactions,
        MIN(r.rn_customer_recent) AS min_recent_rank,
        MAX(r.rn_customer_recent) AS max_recent_rank,
        array_join(array_agg(r.cust_date_key ORDER BY r.cust_date_key), ',') AS cust_date_keys
    FROM ranked r
    JOIN d ON r.date_sk = d.d_date_sk
    GROUP BY
        r.channel,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        r.profit_category
)SELECT * FROM final
