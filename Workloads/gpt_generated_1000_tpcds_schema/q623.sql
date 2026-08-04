WITH
    cs AS (
        SELECT
            cs.cs_order_number,
            cs.cs_net_profit,
            d.d_year AS year,
            cc.cc_name,
            w.w_warehouse_name,
            p.p_promo_name,
            cd.cd_gender,
            ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY cs.cs_net_profit DESC) AS cs_rn
        FROM catalog_sales cs
        JOIN date_dim d           ON cs.cs_sold_date_sk   = d.d_date_sk
        JOIN time_dim t           ON cs.cs_sold_time_sk   = t.t_time_sk
        JOIN call_center cc       ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w          ON cs.cs_warehouse_sk   = w.w_warehouse_sk
        JOIN promotion p          ON cs.cs_promo_sk       = p.p_promo_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        WHERE d.d_year BETWEEN 2000 AND 2002
          AND cc.cc_gmt_offset > -5
          AND p.p_channel_email = 'Y'
          AND w.w_state = 'CA'
          AND cd.cd_credit_rating = 'A'
    ),
    sr AS (
        SELECT
            sr.sr_ticket_number,
            sr.sr_net_loss,
            d.d_year AS year,
            s.s_store_name,
            r.r_reason_desc,
            cd.cd_gender,
            ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY sr.sr_net_loss DESC) AS sr_rn
        FROM store_returns sr
        JOIN date_dim d           ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN time_dim t           ON sr.sr_return_time_sk   = t.t_time_sk
        JOIN store s              ON sr.sr_store_sk        = s.s_store_sk
        JOIN reason r             ON sr.sr_reason_sk       = r.r_reason_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk   = cd.cd_demo_sk
        WHERE d.d_year BETWEEN 2000 AND 2002
          AND s.s_state = 'CA'
          AND r.r_reason_desc LIKE '%damaged%'
          AND cd.cd_gender = 'F'
          AND sr.sr_return_quantity > 1
    ),
    wr AS (
        SELECT
            wr.wr_order_number,
            wr.wr_net_loss,
            d.d_year AS year,
            wp.wp_type,
            r.r_reason_desc AS wr_reason,
            cd.cd_gender,
            ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY wr.wr_net_loss DESC) AS wr_rn
        FROM web_returns wr
        JOIN date_dim d           ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN time_dim t           ON wr.wr_returned_time_sk = t.t_time_sk
        JOIN web_page wp          ON wr.wr_web_page_sk      = wp.wp_web_page_sk
        JOIN reason r             ON wr.wr_reason_sk        = r.r_reason_sk
        JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        WHERE d.d_year BETWEEN 2000 AND 2002
          AND wp.wp_type = 'Product'
          AND r.r_reason_desc LIKE '%damaged%'
          AND cd.cd_gender = 'M'
          AND wr.wr_return_quantity > 0
    ),
    ws AS (
        SELECT
            ws.web_site_id,
            d.d_year AS year,
            ws.web_name,
            ws.web_gmt_offset,
            CASE WHEN ws.web_tax_percentage > 5 THEN 'HighTax' ELSE 'LowTax' END AS tax_category
        FROM web_site ws
        JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
        WHERE d.d_year BETWEEN 2000 AND 2002
    ),
    intersect_orders AS (
        SELECT cs_order_number AS order_id FROM cs
        INTERSECT
        SELECT wr_order_number FROM wr
    ),
    combined AS (
        SELECT
            COALESCE(cs.cs_order_number, sr.sr_ticket_number) AS order_id,
            cs.cs_net_profit,
            sr.sr_net_loss,
            COALESCE(cs.year, sr.year) AS year,
            cs.cc_name,
            sr.s_store_name,
            CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_indicator,
            cs.cs_rn,
            sr.sr_rn,
            CASE WHEN io.order_id IS NOT NULL THEN 1 ELSE 0 END AS in_intersect
        FROM cs
        FULL OUTER JOIN sr ON cs.cs_order_number = sr.sr_ticket_number
        LEFT JOIN intersect_orders io ON io.order_id = COALESCE(cs.cs_order_number, sr.sr_ticket_number)
        WHERE cs.cs_net_profit IS NOT NULL OR sr.sr_net_loss IS NOT NULL
    )
SELECT
    year,
    profit_indicator,
    SUM(net_amount) AS total_amount,
    COUNT(DISTINCT order_id) AS orders_cnt,
    SUM(in_intersect) AS intersect_cnt,
    GROUPING(year) AS g_year,
    GROUPING(profit_indicator) AS g_profit
FROM (
    SELECT
        year,
        profit_indicator,
        COALESCE(cs_net_profit, -sr_net_loss) AS net_amount,
        order_id,
        in_intersect
    FROM combined
) t
GROUP BY GROUPING SETS (
    (year, profit_indicator),
    (year),
    (profit_indicator),
    ()
)
ORDER BY total_amount DESC
OFFSET 10 LIMIT 20
