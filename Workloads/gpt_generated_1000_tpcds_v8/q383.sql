WITH max_promo AS (
    SELECT MAX(p_cost) AS max_cost
    FROM promotion
),
base AS (
    SELECT
        d_sold.d_year                AS d_year,
        p.p_promo_name               AS p_promo_name,
        s.s_state                    AS s_state,
        ws.ws_net_profit             AS ws_net_profit,
        ws.ws_quantity               AS ws_quantity,
        max_promo.max_cost           AS max_cost
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_sold.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_sold.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    CROSS JOIN max_promo
    WHERE d_sold.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND s.s_state = 'CA'
      AND cc.cc_country = 'United States'
      AND wp.wp_type = 'content'
      AND EXISTS (
          SELECT 1
          FROM catalog_page cp2
          WHERE cp2.cp_catalog_number = 4
            AND cp2.cp_start_date_sk = d_sold.d_date_sk
      )
),
agg_all AS (
    SELECT
        d_year,
        p_promo_name,
        s_state,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*)           AS cnt_sales,
        AVG(ws_quantity)   AS avg_quantity,
        MAX(max_cost)      AS max_promo_cost
    FROM base
    GROUP BY GROUPING SETS (
        (d_year, p_promo_name, s_state),
        (d_year, p_promo_name),
        (d_year),
        ()
    )
),
agg_filtered AS (
    SELECT
        d_year,
        p_promo_name,
        s_state,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*)           AS cnt_sales,
        AVG(ws_quantity)   AS avg_quantity,
        MAX(max_cost)      AS max_promo_cost
    FROM base
    WHERE ws_quantity < 5
    GROUP BY GROUPING SETS (
        (d_year, p_promo_name, s_state),
        (d_year, p_promo_name),
        (d_year),
        ()
    )
)
SELECT *
FROM (
    SELECT * FROM agg_all
    EXCEPT
    SELECT * FROM agg_filtered
) result
ORDER BY total_profit DESC
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
