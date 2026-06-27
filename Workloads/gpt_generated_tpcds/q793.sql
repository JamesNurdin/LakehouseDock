WITH sales_agg AS (
    SELECT
        d_sales.d_year,
        d_sales.d_moy,
        wp.wp_type,
        SUM(ws.ws_net_paid)               AS total_sales,
        SUM(ws.ws_net_profit)             AS total_profit,
        SUM(ws.ws_quantity)               AS total_quantity,
        SUM(ws.ws_ext_discount_amt)       AS total_discount
    FROM web_sales ws
    JOIN date_dim d_sales
        ON ws.ws_sold_date_sk = d_sales.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY
        d_sales.d_year,
        d_sales.d_moy,
        wp.wp_type
),
returns_agg AS (
    SELECT
        d_return.d_year,
        d_return.d_moy,
        wp.wp_type,
        SUM(wr.wr_return_amt)        AS total_return_amount,
        SUM(wr.wr_return_quantity)   AS total_return_quantity,
        SUM(wr.wr_net_loss)          AS total_return_loss
    FROM web_returns wr
    JOIN date_dim d_return
        ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY
        d_return.d_year,
        d_return.d_moy,
        wp.wp_type
)
SELECT
    COALESCE(s.d_year, r.d_year)               AS year,
    COALESCE(s.d_moy, r.d_moy)                 AS month,
    COALESCE(s.wp_type, r.wp_type)             AS page_type,
    COALESCE(s.total_sales, 0)                 AS total_sales,
    COALESCE(s.total_profit, 0)                AS total_profit,
    COALESCE(r.total_return_amount, 0)        AS total_return_amount,
    COALESCE(r.total_return_loss, 0)          AS total_return_loss,
    COALESCE(s.total_quantity, 0)              AS total_quantity,
    COALESCE(r.total_return_quantity, 0)      AS total_return_quantity,
    CASE
        WHEN COALESCE(s.total_quantity, 0) = 0 THEN 0
        ELSE (COALESCE(r.total_return_quantity, 0) * 1.0) / s.total_quantity
    END                                        AS return_rate,
    CASE
        WHEN COALESCE(s.total_quantity, 0) = 0 THEN 0
        ELSE (s.total_discount * 1.0) / s.total_quantity
    END                                        AS avg_discount,
    (COALESCE(s.total_profit, 0) - COALESCE(r.total_return_loss, 0)) AS net_profit_after_returns
FROM sales_agg s
FULL OUTER JOIN returns_agg r
    ON s.d_year = r.d_year
   AND s.d_moy = r.d_moy
   AND s.wp_type = r.wp_type
ORDER BY year, month, page_type
