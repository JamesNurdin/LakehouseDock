WITH filtered_sales AS (
    SELECT *
    FROM catalog_sales cs
    WHERE cs.cs_catalog_page_sk IN (
            SELECT cp.cp_catalog_page_sk
            FROM catalog_page cp
            WHERE cp.cp_type = 'SPECIAL'
        )
        AND cs.cs_sold_date_sk BETWEEN 2451910 AND 2451915
),
joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        cp.cp_department,
        sm.sm_type,
        td.t_shift,
        td.t_second,
        cr.cr_return_amount,
        cr.cr_store_credit
    FROM filtered_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        AND cr.cr_returned_time_sk = td.t_time_sk
    WHERE cp.cp_department IN ('Electronics', 'Books')
        AND sm.sm_contract = 'A5BYO1qH8HGTTN'
        AND td.t_shift = 'second'
        AND td.t_second BETWEEN 5 AND 12
        AND cr.cr_store_credit > 10.00
),
agg AS (
    SELECT
        cp_department,
        sm_type,
        t_shift,
        COUNT(DISTINCT cs_order_number) AS orders_cnt,
        SUM(cs_net_paid) AS total_net_paid,
        AVG(cr_return_amount) AS avg_return_amount,
        MIN(cs_sold_date_sk) AS first_sold_date_sk,
        MAX(cs_sold_date_sk) AS last_sold_date_sk
    FROM joined
    GROUP BY cp_department, sm_type, t_shift
)
SELECT
    cp_department,
    sm_type,
    t_shift,
    orders_cnt,
    total_net_paid,
    avg_return_amount,
    first_sold_date_sk,
    last_sold_date_sk,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS rn
FROM agg
ORDER BY rn
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
