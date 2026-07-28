WITH refunded_addr AS (
    SELECT ca_address_sk,
           ca_state,
           ca_location_type,
           ca_city
    FROM customer_address
    WHERE ca_state = 'CA'
      AND ca_location_type = 'apartment'
),
returning_addr AS (
    SELECT ca_address_sk,
           ca_city AS ret_city
    FROM customer_address
    WHERE ca_city LIKE 'San%'
),
join_base AS (
    SELECT
        cc.cc_name,
        cc.cc_tax_percentage,
        cc.cc_country,
        cp.cp_department,
        cp.cp_catalog_page_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        rfa.ca_state AS refunded_state,
        rfa.ca_location_type AS refunded_loc_type,
        ra.ret_city
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN refunded_addr rfa
        ON cr.cr_refunded_addr_sk = rfa.ca_address_sk
    JOIN returning_addr ra
        ON cr.cr_returning_addr_sk = ra.ca_address_sk
    WHERE cc.cc_country = 'United States'
      AND cc.cc_tax_percentage > 0.05
      AND cp.cp_start_date_sk BETWEEN 2451000 AND 2451500
      AND cp.cp_catalog_page_number IN (10, 15, 19)
      AND cr.cr_return_quantity > 1
      AND cr.cr_return_amount > 0
),
agg AS (
    SELECT
        cc_name,
        cc_tax_percentage,
        cp_department,
        cp_catalog_page_number,
        refunded_state,
        refunded_loc_type,
        ret_city,
        SUM(cr_return_quantity) AS total_qty,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss
    FROM join_base
    GROUP BY
        cc_name,
        cc_tax_percentage,
        cp_department,
        cp_catalog_page_number,
        refunded_state,
        refunded_loc_type,
        ret_city
    HAVING SUM(cr_return_quantity) > 10
),
final AS (
    SELECT
        *,
        AVG(total_return_amount) OVER (PARTITION BY cc_name) AS avg_return_amount_per_cc,
        RANK() OVER (PARTITION BY cp_department ORDER BY total_net_loss DESC) AS dept_net_loss_rank,
        CASE
            WHEN total_net_loss > (SELECT AVG(cr_net_loss) FROM catalog_returns) THEN 'Above Avg'
            ELSE 'Below Avg'
        END AS net_loss_category
    FROM agg
)
SELECT
    cc_name,
    cc_tax_percentage,
    cp_department,
    cp_catalog_page_number,
    refunded_state,
    refunded_loc_type,
    ret_city,
    total_qty,
    total_return_amount,
    total_net_loss,
    avg_return_amount_per_cc,
    dept_net_loss_rank,
    net_loss_category
FROM final
ORDER BY total_net_loss DESC, dept_net_loss_rank
LIMIT 100
