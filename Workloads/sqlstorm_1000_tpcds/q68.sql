WITH
    sales_union AS (
        SELECT ss.ss_customer_sk AS customer_sk,
               ss.ss_sold_date_sk AS sold_date_sk,
               ss.ss_net_paid AS net_paid,
               ss.ss_net_profit AS net_profit,
               ss.ss_ticket_number AS order_number,
               'store' AS sales_channel
        FROM store_sales ss
        LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year BETWEEN 2000 AND 2002
        UNION ALL
        SELECT ws.ws_bill_customer_sk AS customer_sk,
               ws.ws_sold_date_sk AS sold_date_sk,
               ws.ws_net_paid AS net_paid,
               ws.ws_net_profit AS net_profit,
               ws.ws_order_number AS order_number,
               'web' AS sales_channel
        FROM web_sales ws
        LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year BETWEEN 2000 AND 2002
        UNION ALL
        SELECT cs.cs_bill_customer_sk AS customer_sk,
               cs.cs_sold_date_sk AS sold_date_sk,
               cs.cs_net_paid AS net_paid,
               cs.cs_net_profit AS net_profit,
               cs.cs_order_number AS order_number,
               'catalog' AS sales_channel
        FROM catalog_sales cs
        LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year BETWEEN 2000 AND 2002
    ),
    sales_agg AS (
        SELECT customer_sk,
               COUNT(*) AS total_orders,
               SUM(net_paid) AS total_net_paid,
               SUM(net_profit) AS total_net_profit,
               MAX(sold_date_sk) AS last_sold_date_sk,
               MIN(sold_date_sk) AS first_sold_date_sk
        FROM sales_union
        GROUP BY customer_sk
    ),
    returns_union AS (
        SELECT sr.sr_customer_sk AS customer_sk,
               sr.sr_returned_date_sk AS return_date_sk,
               sr.sr_net_loss AS net_loss,
               'store' AS return_channel
        FROM store_returns sr
        UNION ALL
        SELECT wr.wr_refunded_customer_sk AS customer_sk,
               wr.wr_returned_date_sk AS return_date_sk,
               wr.wr_net_loss AS net_loss,
               'web' AS return_channel
        FROM web_returns wr
        UNION ALL
        SELECT cr.cr_refunded_customer_sk AS customer_sk,
               cr.cr_returned_date_sk AS return_date_sk,
               cr.cr_net_loss AS net_loss,
               'catalog' AS return_channel
        FROM catalog_returns cr
    ),
    returns_agg AS (
        SELECT customer_sk,
               SUM(net_loss) AS total_net_loss,
               COUNT(*) AS total_returns,
               MAX(return_date_sk) AS last_return_date_sk
        FROM returns_union
        GROUP BY customer_sk
    ),
    join_sales_returns AS (
        SELECT 
            COALESCE(s.customer_sk, r.customer_sk) AS customer_sk,
            s.total_net_profit,
            s.total_orders,
            s.last_sold_date_sk,
            r.total_net_loss,
            r.total_returns,
            r.last_return_date_sk
        FROM sales_agg s
        FULL OUTER JOIN returns_agg r ON s.customer_sk = r.customer_sk
    ),
    demo_info AS (
        SELECT c.c_customer_sk AS customer_sk,
               c.c_first_name,
               c.c_last_name,
               c.c_customer_id,
               c.c_birth_year,
               cd.cd_gender,
               cd.cd_marital_status,
               hd.hd_income_band_sk,
               ib.ib_lower_bound,
               ib.ib_upper_bound,
               CASE
                   WHEN cd.cd_gender = 'M' THEN 'Male'
                   WHEN cd.cd_gender = 'F' THEN 'Female'
                   ELSE 'Other'
               END AS gender_desc,
               CONCAT(c.c_first_name, ' ', c.c_last_name, ' (', c.c_customer_id, ')') AS customer_label
        FROM customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    ),
    net_profit_calc AS (
        SELECT
            d.customer_sk,
            d.customer_label,
            d.gender_desc,
            d.ib_lower_bound,
            d.ib_upper_bound,
            COALESCE(jsr.total_net_profit, 0) - COALESCE(jsr.total_net_loss, 0) AS net_profit_after_returns,
            COALESCE(jsr.total_orders, 0) AS total_orders,
            COALESCE(jsr.total_returns, 0) AS total_returns,
            (SELECT d2.d_date FROM date_dim d2 WHERE d2.d_date_sk = jsr.last_sold_date_sk) AS last_purchase_date,
            (SELECT d3.d_date FROM date_dim d3 WHERE d3.d_date_sk = jsr.last_return_date_sk) AS last_return_date
        FROM demo_info d
        LEFT JOIN join_sales_returns jsr ON d.customer_sk = jsr.customer_sk
    ),
    ranked_customers AS (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY ib_lower_bound, ib_upper_bound
                   ORDER BY net_profit_after_returns DESC NULLS LAST
               ) AS rank_within_income_band
        FROM net_profit_calc
    ),
    top_customers AS (
        SELECT *
        FROM ranked_customers
        WHERE net_profit_after_returns > 10000
    ),
    low_profit_customers AS (
        SELECT *
        FROM ranked_customers
        WHERE net_profit_after_returns < 0
    ),
    common_customers AS (
        SELECT customer_sk FROM top_customers
        INTERSECT
        SELECT customer_sk FROM low_profit_customers
    )
SELECT
    rc.customer_sk,
    rc.customer_label,
    rc.gender_desc,
    rc.ib_lower_bound,
    rc.ib_upper_bound,
    rc.net_profit_after_returns,
    rc.total_orders,
    rc.total_returns,
    rc.last_purchase_date,
    rc.last_return_date,
    rc.rank_within_income_band,
    CASE
        WHEN rc.rank_within_income_band <= 10 THEN 'Top 10 in income band'
        WHEN rc.rank_within_income_band <= 100 THEN 'Top 100 in income band'
        ELSE 'Other'
    END AS rank_category,
    CASE WHEN cc.customer_sk IS NOT NULL THEN 'Y' ELSE 'N' END AS in_both_top_and_low
FROM (
    SELECT * FROM top_customers
    UNION ALL
    SELECT * FROM low_profit_customers
) rc
LEFT JOIN common_customers cc ON rc.customer_sk = cc.customer_sk
ORDER BY rc.net_profit_after_returns DESC NULLS LAST
LIMIT 500
