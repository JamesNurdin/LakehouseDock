WITH
    store_ret AS (
        SELECT sr.sr_customer_sk AS c_customer_sk, SUM(sr.sr_net_loss) AS store_return_loss
        FROM store_returns sr
        GROUP BY sr.sr_customer_sk
    ),
    catalog_ret AS (
        SELECT cr.cr_returning_customer_sk AS c_customer_sk, SUM(cr.cr_net_loss) AS catalog_return_loss
        FROM catalog_returns cr
        GROUP BY cr.cr_returning_customer_sk
    ),
    web_ret AS (
        SELECT wr.wr_refunded_customer_sk AS c_customer_sk, SUM(wr.wr_net_loss) AS web_return_loss
        FROM web_returns wr
        GROUP BY wr.wr_refunded_customer_sk
    ),
    all_sales AS (
        SELECT
            c.c_customer_sk,
            c.c_customer_id,
            d.d_year,
            ss.ss_quantity AS quantity,
            ss.ss_net_profit AS net_profit,
            ss.ss_ticket_number AS order_number,
            'store' AS channel
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        UNION ALL
        SELECT
            c.c_customer_sk,
            c.c_customer_id,
            d.d_year,
            cs.cs_quantity,
            cs.cs_net_profit,
            cs.cs_order_number,
            'catalog' AS channel
        FROM catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        UNION ALL
        SELECT
            c.c_customer_sk,
            c.c_customer_id,
            d.d_year,
            ws.ws_quantity,
            ws.ws_net_profit,
            ws.ws_order_number,
            'web' AS channel
        FROM web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    ),
    sales_agg AS (
        SELECT
            c_customer_sk,
            c_customer_id,
            d_year,
            SUM(net_profit) AS total_net_profit,
            SUM(CASE WHEN channel = 'store' THEN net_profit ELSE 0 END) AS store_net_profit,
            SUM(CASE WHEN channel = 'catalog' THEN net_profit ELSE 0 END) AS catalog_net_profit,
            SUM(CASE WHEN channel = 'web' THEN net_profit ELSE 0 END) AS web_net_profit,
            COUNT(DISTINCT order_number) AS total_orders,
            COUNT(DISTINCT CASE WHEN channel = 'store' THEN order_number END) AS store_orders,
            COUNT(DISTINCT CASE WHEN channel = 'catalog' THEN order_number END) AS catalog_orders,
            COUNT(DISTINCT CASE WHEN channel = 'web' THEN order_number END) AS web_orders,
            SUM(quantity) AS total_quantity
        FROM all_sales
        WHERE d_year = 2002
        GROUP BY c_customer_sk, c_customer_id, d_year
    ),
    returns_agg AS (
        SELECT
            c.c_customer_sk,
            COALESCE(sr.store_return_loss, 0) + COALESCE(cr.catalog_return_loss, 0) + COALESCE(wr.web_return_loss, 0) AS total_return_loss,
            COALESCE(sr.store_return_loss, 0) AS store_return_loss,
            COALESCE(cr.catalog_return_loss, 0) AS catalog_return_loss,
            COALESCE(wr.web_return_loss, 0) AS web_return_loss
        FROM customer c
        LEFT JOIN store_ret sr ON c.c_customer_sk = sr.c_customer_sk
        LEFT JOIN catalog_ret cr ON c.c_customer_sk = cr.c_customer_sk
        LEFT JOIN web_ret wr ON c.c_customer_sk = wr.c_customer_sk
    ),
    customer_demo AS (
        SELECT
            c.c_customer_sk,
            cd.cd_gender,
            cd.cd_marital_status,
            cd.cd_education_status,
            cd.cd_credit_rating,
            ib.ib_lower_bound,
            ib.ib_upper_bound
        FROM customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    ),
    final AS (
        SELECT
            s.c_customer_sk,
            s.c_customer_id,
            s.d_year,
            s.total_net_profit,
            s.store_net_profit,
            s.catalog_net_profit,
            s.web_net_profit,
            s.total_orders,
            s.total_quantity,
            COALESCE(r.total_return_loss, 0) AS total_return_loss,
            (s.total_net_profit - COALESCE(r.total_return_loss, 0)) AS net_profit_after_returns,
            cd.cd_gender,
            cd.cd_marital_status,
            cd.cd_education_status,
            cd.cd_credit_rating,
            cd.ib_lower_bound,
            cd.ib_upper_bound
        FROM sales_agg s
        LEFT JOIN returns_agg r ON s.c_customer_sk = r.c_customer_sk
        LEFT JOIN customer_demo cd ON s.c_customer_sk = cd.c_customer_sk
    )
SELECT
    t.c_customer_id,
    t.d_year,
    t.net_profit_after_returns,
    t.cd_gender,
    t.cd_marital_status,
    t.cd_education_status,
    t.cd_credit_rating,
    t.ib_lower_bound,
    t.ib_upper_bound,
    t.rn AS rank
FROM (
    SELECT
        f.c_customer_id,
        f.d_year,
        f.net_profit_after_returns,
        f.cd_gender,
        f.cd_marital_status,
        f.cd_education_status,
        f.cd_credit_rating,
        f.ib_lower_bound,
        f.ib_upper_bound,
        ROW_NUMBER() OVER (PARTITION BY f.d_year ORDER BY f.net_profit_after_returns DESC) AS rn
    FROM final f
    WHERE f.net_profit_after_returns > 0
) t
WHERE t.rn <= 10
ORDER BY t.d_year, t.rn
