WITH joined AS (
    SELECT
        cp.cp_department,
        cp.cp_description,
        t.t_hour,
        t.t_minute,
        t.t_second,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        c_ref.c_birth_year,
        ca_ref.ca_state,
        cr.cr_net_loss,
        sr.sr_net_loss,
        (cr.cr_net_loss + sr.sr_net_loss) AS combined_net_loss,
        CASE
            WHEN ca_ref.ca_state = 'CA' THEN 'West'
            ELSE 'Other'
        END AS region_category
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN store_returns sr
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c_ref
        ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer c_sr
        ON sr.sr_customer_sk = c_sr.c_customer_sk
    JOIN customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    WHERE
        t.t_hour BETWEEN 8 AND 20
        AND t.t_minute IN (0, 15, 30, 45)
        AND cp.cp_department = 'DEPARTMENT'
        AND c_ref.c_birth_year >= 1970
        AND ca_ref.ca_state = 'CA'
        AND sr.sr_store_credit > 100
),
aggregated AS (
    SELECT
        cp_department,
        t_hour,
        region_category,
        SUM(cr_return_amount) AS total_catalog_return_amount,
        SUM(sr_return_amt) AS total_store_return_amount,
        SUM(combined_net_loss) AS total_combined_net_loss,
        COUNT(DISTINCT cr_return_quantity) AS distinct_catalog_return_qty,
        COUNT(DISTINCT sr_return_quantity) AS distinct_store_return_qty
    FROM joined
    GROUP BY ROLLUP (cp_department, t_hour, region_category)
    HAVING SUM(combined_net_loss) > 0
)
SELECT
    cp_department,
    t_hour,
    region_category,
    total_catalog_return_amount,
    total_store_return_amount,
    total_combined_net_loss,
    distinct_catalog_return_qty,
    distinct_store_return_qty,
    RANK() OVER (PARTITION BY cp_department ORDER BY total_combined_net_loss DESC) AS loss_rank
FROM aggregated
ORDER BY cp_department NULLS LAST, t_hour NULLS LAST, loss_rank
LIMIT 100
