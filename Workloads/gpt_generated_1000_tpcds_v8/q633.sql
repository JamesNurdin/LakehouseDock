WITH
    sr_base AS (
        SELECT
            sr.sr_item_sk,
            sr.sr_returned_date_sk,
            sr.sr_return_quantity,
            sr.sr_return_amt,
            i.i_category,
            i.i_brand,
            c.c_customer_id,
            cd.cd_gender,
            s.s_store_id,
            t.t_hour,
            t.t_meal_time
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        WHERE c.c_preferred_cust_flag = 'Y'
          AND i.i_current_price > 10
          AND s.s_state = 'CA'
          AND t.t_meal_time = 'Dinner'
    ),
    ws_base AS (
        SELECT
            ws.ws_item_sk,
            ws.ws_sold_date_sk,
            ws.ws_quantity,
            ws.ws_net_paid,
            i.i_category,
            i.i_brand,
            c.c_customer_id,
            cd.cd_gender,
            p.p_promo_name,
            wp.wp_type,
            t.t_hour,
            t.t_meal_time
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        WHERE c.c_preferred_cust_flag = 'Y'
          AND i.i_current_price > 10
          AND p.p_discount_active = 'Y'
          AND t.t_meal_time = 'Dinner'
    ),
    combined AS (
        SELECT *
        FROM sr_base
        FULL OUTER JOIN ws_base
            ON sr_base.sr_item_sk = ws_base.ws_item_sk
            AND sr_base.t_hour = ws_base.t_hour
    ),
    filtered_items AS (
        SELECT i.i_item_sk
        FROM item i
        WHERE i.i_current_price BETWEEN 20 AND 100
        INTERSECT
        SELECT ws.ws_item_sk
        FROM web_sales ws
        WHERE ws.ws_net_paid > 0
    ),
    unioned AS (
        SELECT
            sr.sr_item_sk AS item_key,
            i.i_category,
            i.i_brand,
            sr.sr_return_amt AS return_amt,
            0.0 AS net_paid
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        WHERE sr.sr_item_sk IN (SELECT i_item_sk FROM filtered_items)

        UNION DISTINCT

        SELECT
            ws.ws_item_sk AS item_key,
            i.i_category,
            i.i_brand,
            0.0 AS return_amt,
            ws.ws_net_paid AS net_paid
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        WHERE ws.ws_item_sk IN (SELECT i_item_sk FROM filtered_items)
    ),
    ranked AS (
        SELECT
            u.item_key,
            u.i_category,
            u.i_brand,
            SUM(u.return_amt) AS total_return_amt,
            SUM(u.net_paid) AS total_net_paid,
            CASE
                WHEN SUM(u.return_amt) > SUM(u.net_paid) THEN 'Loss'
                WHEN SUM(u.return_amt) = SUM(u.net_paid) THEN 'Break-even'
                ELSE 'Profit'
            END AS profit_status,
            ROW_NUMBER() OVER (PARTITION BY u.i_category ORDER BY SUM(u.return_amt) DESC) AS rn_category,
            RANK() OVER (ORDER BY SUM(u.return_amt) DESC) AS overall_rank
        FROM unioned u
        GROUP BY GROUPING SETS (
            (u.item_key, u.i_category, u.i_brand),
            (u.i_category, u.i_brand),
            (u.i_category),
            ()
        )
        HAVING NOT EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_item_sk = u.item_key
              AND sr2.sr_return_amt > 5000
        )
    )
SELECT
    r.item_key,
    r.i_category,
    r.i_brand,
    r.total_return_amt,
    r.total_net_paid,
    r.profit_status,
    r.rn_category,
    r.overall_rank,
    lc.return_cnt
FROM ranked r
CROSS JOIN LATERAL (
    SELECT COUNT(*) AS return_cnt
    FROM store_returns sr3
    WHERE sr3.sr_item_sk = r.item_key
) lc
WHERE r.rn_category <= 5
ORDER BY r.overall_rank, r.item_key
LIMIT 100
