WITH cs_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_time_sk,
        cs.cs_net_profit,
        td.t_time      AS cs_time,
        td.t_am_pm    AS cs_am_pm,
        td.t_meal_time AS cs_meal_time
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
),
ws_base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_net_profit,
        td.t_time      AS ws_time,
        td.t_am_pm    AS ws_am_pm,
        wp.wp_web_page_sk,
        wp.wp_web_page_id,
        wp.wp_rec_start_date
    FROM web_sales ws
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
),
wr_base AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_return_amt,
        td.t_time      AS ret_time,
        td.t_am_pm    AS ret_am_pm,
        wp.wp_web_page_sk AS ret_page_sk,
        wp.wp_web_page_id AS ret_page_id
    FROM web_returns wr
    JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
)
SELECT
    COALESCE(cs.cs_order_number, ws.ws_order_number)                     AS order_number,
    SUM(cs.cs_net_profit)                                               AS catalog_profit_total,
    SUM(ws.ws_net_profit)                                               AS web_profit_total,
    CASE
        WHEN COALESCE(td_extra1.t_am_pm, td_extra2.t_am_pm) = 'PM' THEN 'Evening'
        ELSE 'Morning'
    END                                                                AS period,
    ROW_NUMBER() OVER (ORDER BY COALESCE(cs.cs_order_number, ws.ws_order_number)) AS rn,
    (
        SELECT SUM(wr2.wr_return_amt)
        FROM web_returns wr2
        WHERE wr2.wr_web_page_sk = wp_alt.wp_web_page_sk
    )                                                                   AS total_return_amount,
    SUM(COALESCE(wr.wr_return_amt, 0))                                 AS total_return_from_wr
FROM cs_base cs
FULL OUTER JOIN ws_base ws
    ON cs.cs_order_number = ws.ws_order_number
LEFT JOIN wr_base wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
LEFT JOIN time_dim td_extra1
    ON cs.cs_sold_time_sk = td_extra1.t_time_sk
LEFT JOIN time_dim td_extra2
    ON ws.ws_sold_time_sk = td_extra2.t_time_sk
LEFT JOIN web_page wp_alt
    ON ws.wp_web_page_sk = wp_alt.wp_web_page_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr_chk
    WHERE wr_chk.wr_order_number = cs.cs_order_number
)
GROUP BY
    COALESCE(cs.cs_order_number, ws.ws_order_number),
    td_extra1.t_am_pm,
    td_extra2.t_am_pm,
    wp_alt.wp_web_page_sk
HAVING COALESCE(cs.cs_order_number, ws.ws_order_number) IN (
    SELECT cs_order_number FROM catalog_sales
    EXCEPT
    SELECT ws_order_number FROM web_sales
)
ORDER BY rn
LIMIT 100
