WITH
    store_sales_filtered AS (
        SELECT ss.*
        FROM store_sales ss
        WHERE ss.ss_quantity > 5
          AND ss.ss_sales_price > 100
    ),
    web_sales_filtered AS (
        SELECT ws.*
        FROM web_sales ws
        WHERE ws.ws_quantity > 3
          AND ws.ws_sales_price > 150
    ),
    intersect_keys AS (
        SELECT ss_ticket_number AS key
        FROM store_sales_filtered
        INTERSECT
        SELECT ws_order_number AS key
        FROM web_sales_filtered
    ),
    base AS (
        SELECT
            s.s_store_id,
            s.s_state,
            d.d_year,
            p.p_promo_name,
            p.p_channel_tv,
            cc.cc_state,
            cp.cp_department,
            cd.cd_gender,
            hd.hd_income_band_sk,
            ss.ss_ticket_number,
            ws.ws_order_number,
            ss.ss_net_paid,
            ws.ws_net_paid,
            sr.sr_net_loss,
            wr.wr_net_loss
        FROM store_sales_filtered ss
        RIGHT JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d
            ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN promotion p
            ON ss.ss_promo_sk = p.p_promo_sk
        JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN store_returns sr
            ON sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_store_sk = s.s_store_sk
            AND sr.sr_returned_date_sk = d.d_date_sk
        LEFT JOIN web_sales ws
            ON ws.ws_sold_date_sk = d.d_date_sk
        LEFT JOIN web_returns wr
            ON wr.wr_order_number = ws.ws_order_number
            AND wr.wr_returned_date_sk = d.d_date_sk
        LEFT JOIN call_center cc
            ON cc.cc_closed_date_sk = d.d_date_sk
        LEFT JOIN catalog_page cp
            ON cp.cp_start_date_sk = d.d_date_sk
        WHERE d.d_year = 2002
          AND p.p_channel_tv = 'N'
          AND cc.cc_state = 'CA'
          AND cp.cp_department = 'DEPARTMENT'
          AND s.s_state = 'TX'
          AND cd.cd_gender = 'F'
          AND hd.hd_income_band_sk IN (1, 2)
          AND ss.ss_ticket_number IN (SELECT key FROM intersect_keys)
    )
SELECT
    s_state,
    d_year,
    p_promo_name,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(ws_net_paid) AS total_web_sales,
    COUNT(DISTINCT ss_ticket_number) AS distinct_store_tickets,
    COUNT(DISTINCT ws_order_number) AS distinct_web_orders,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
FROM base
GROUP BY GROUPING SETS (
    (s_state, d_year, p_promo_name),
    (s_state, d_year),
    (s_state),
    ()
)
ORDER BY total_store_sales DESC
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
