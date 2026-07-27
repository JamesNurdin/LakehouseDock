/*
Goal: Produce a ranked list of store and web sales combined with time and website attributes, showing each store's rank within its shift based on net paid (including tax), a running sum of net paid for the last three stores in the same shift, and filtering on several business dimensions.
*/
WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_net_paid,
        ss.ss_store_sk,
        ss.ss_net_paid_inc_tax,
        td.t_shift,
        td.t_am_pm,
        ws_site.web_name,
        ws_site.web_mkt_id,
        ws_site.web_company_name
    FROM
        web_sales ws
        JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
        JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
        JOIN store_sales ss ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE
        td.t_shift IN ('first', 'second')                -- shift filter
        AND td.t_am_pm = 'PM'                             -- AM/PM filter
        AND ws_site.web_mkt_id IN (1, 3, 5)               -- market id filter
        AND ss.ss_promo_sk NOT IN (938, 1173)            -- promo filter
        AND ss.ss_net_paid_inc_tax > 500                  -- net paid threshold
        AND EXISTS (
            SELECT 1
            FROM store_sales ss2
            WHERE ss2.ss_store_sk = ss.ss_store_sk
              AND ss2.ss_net_profit > 200               -- profit filter via subquery
        )
)
SELECT
    fs.ws_order_number,
    fs.ws_sold_date_sk,
    fs.ws_sold_time_sk,
    fs.ws_net_paid,
    fs.ss_store_sk,
    fs.ss_net_paid_inc_tax,
    fs.t_shift,
    fs.web_name,
    fs.web_mkt_id,
    fs.web_company_name,
    RANK() OVER (PARTITION BY fs.t_shift ORDER BY fs.ss_net_paid_inc_tax DESC) AS store_rank_in_shift,
    SUM(fs.ss_net_paid_inc_tax) OVER (
        PARTITION BY fs.t_shift
        ORDER BY fs.ss_store_sk
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS running_sum_store_net
FROM
    filtered_sales fs
ORDER BY
    fs.t_shift,
    store_rank_in_shift,
    fs.ws_order_number
LIMIT 100
