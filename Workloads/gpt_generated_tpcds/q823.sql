WITH
    sales AS (
        SELECT
            ws.ws_sold_date_sk,
            ws.ws_web_site_sk,
            ws.ws_net_profit,
            ws.ws_ext_discount_amt,
            ws.ws_order_number,
            d.d_date,
            d.d_year,
            d.d_moy
        FROM web_sales ws
        JOIN date_dim d
          ON ws.ws_sold_date_sk = d.d_date_sk
    ),
    sites AS (
        SELECT
            ws.web_site_sk,
            ws.web_site_id,
            ws.web_name,
            open_d.d_date AS open_date,
            close_d.d_date AS close_date
        FROM web_site ws
        LEFT JOIN date_dim open_d
          ON ws.web_open_date_sk = open_d.d_date_sk
        LEFT JOIN date_dim close_d
          ON ws.web_close_date_sk = close_d.d_date_sk
    ),
    filtered_sales AS (
        SELECT
            s.ws_web_site_sk,
            s.ws_net_profit,
            s.ws_ext_discount_amt,
            s.ws_order_number,
            s.d_year,
            s.d_moy
        FROM sales s
        JOIN sites st
          ON s.ws_web_site_sk = st.web_site_sk
        WHERE s.d_year = 2000
          AND s.d_date >= st.open_date
          AND (st.close_date IS NULL OR s.d_date <= st.close_date)
    ),
    monthly AS (
        SELECT
            st.web_site_id,
            st.web_name,
            f.d_year,
            f.d_moy,
            sum(f.ws_net_profit) AS total_profit,
            sum(f.ws_ext_discount_amt) AS total_discount,
            count(DISTINCT f.ws_order_number) AS order_count
        FROM filtered_sales f
        JOIN sites st
          ON f.ws_web_site_sk = st.web_site_sk
        GROUP BY
            st.web_site_id,
            st.web_name,
            f.d_year,
            f.d_moy
    )
SELECT
    m.web_site_id,
    m.web_name,
    m.d_year,
    m.d_moy,
    m.total_profit,
    m.total_discount,
    m.order_count,
    lag(m.total_profit) OVER (PARTITION BY m.web_site_id ORDER BY m.d_year, m.d_moy) AS prior_month_profit,
    CASE
        WHEN lag(m.total_profit) OVER (PARTITION BY m.web_site_id ORDER BY m.d_year, m.d_moy) = 0 THEN NULL
        ELSE (m.total_profit - lag(m.total_profit) OVER (PARTITION BY m.web_site_id ORDER BY m.d_year, m.d_moy))
             / lag(m.total_profit) OVER (PARTITION BY m.web_site_id ORDER BY m.d_year, m.d_moy)
    END AS profit_growth_ratio
FROM monthly m
ORDER BY m.total_profit DESC
LIMIT 50
