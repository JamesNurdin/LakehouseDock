WITH
    sales_data AS (
        SELECT
            ss.ss_ticket_number AS ticket_number,
            ca.ca_state,
            cd.cd_gender,
            i.i_category,
            i.i_item_sk,
            ss.ss_net_paid AS net_amount,
            ss.ss_net_profit AS profit,
            t.t_hour,
            p.p_promo_name AS promo_name
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk AND p.p_item_sk = i.i_item_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        WHERE
            ca.ca_state = 'CA'
            AND cd.cd_marital_status IN ('M', 'S')
            AND cd.cd_dep_employed_count >= 2
            AND i.i_current_price BETWEEN 20 AND 150
            AND p.p_discount_active = 'Y'
            AND t.t_hour BETWEEN 10 AND 16
    ),
    returns_data AS (
        SELECT
            sr.sr_ticket_number AS ticket_number,
            ca.ca_state,
            cd.cd_gender,
            i.i_category,
            i.i_item_sk,
            -(sr.sr_return_amt + sr.sr_return_tax) AS net_amount,
            -sr.sr_net_loss AS profit,
            t.t_hour,
            NULL AS promo_name
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        WHERE
            ca.ca_state = 'CA'
            AND cd.cd_marital_status IN ('M', 'S')
            AND cd.cd_dep_employed_count >= 2
            AND i.i_current_price BETWEEN 20 AND 150
            AND t.t_hour BETWEEN 10 AND 16
            AND sr.sr_return_tax > 5.0
    ),
    union_data AS (
        SELECT * FROM sales_data
        UNION
        SELECT * FROM returns_data
    ),
    intersect_tickets AS (
        SELECT ticket_number FROM sales_data
        INTERSECT
        SELECT ticket_number FROM returns_data
    ),
    except_tickets AS (
        SELECT ticket_number FROM sales_data
        EXCEPT
        SELECT ticket_number FROM returns_data
    ),
    filtered_data AS (
        SELECT
            u.ticket_number,
            u.ca_state,
            u.cd_gender,
            u.i_category,
            u.i_item_sk,
            u.net_amount,
            u.profit,
            u.t_hour,
            CASE WHEN u.promo_name IS NOT NULL THEN 'sale' ELSE 'return' END AS trans_type
        FROM union_data u
        WHERE EXISTS (
            SELECT 1
            FROM promotion p_check
            WHERE p_check.p_item_sk = u.i_item_sk
              AND p_check.p_discount_active = 'Y'
        )
    )
SELECT
    ca_state,
    cd_gender,
    i_category,
    trans_type,
    SUM(net_amount) AS total_net_amount,
    SUM(profit) AS total_profit,
    CASE 
        WHEN SUM(profit) > 1000 THEN 'High'
        WHEN SUM(profit) > 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_bracket,
    COUNT(DISTINCT ticket_number) AS distinct_tickets,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY SUM(profit) DESC) AS profit_rank,
    MAX(CASE WHEN ticket_number IN (SELECT ticket_number FROM intersect_tickets) THEN 1 ELSE 0 END) AS has_intersect,
    MAX(CASE WHEN ticket_number IN (SELECT ticket_number FROM except_tickets) THEN 1 ELSE 0 END) AS has_except
FROM filtered_data
GROUP BY ROLLUP (ca_state, cd_gender, i_category, trans_type)
ORDER BY ca_state, cd_gender, i_category, trans_type
LIMIT 100
