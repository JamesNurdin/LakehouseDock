WITH main AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_current_price,
        sr.sr_return_quantity,
        sr.sr_net_loss AS store_net_loss,
        cr.cr_return_amount,
        cr.cr_net_loss AS catalog_net_loss,
        c.c_customer_id,
        c.c_customer_sk AS customer_sk,
        c.c_birth_month,
        cd.cd_gender,
        ca.ca_city,
        r.r_reason_desc,
        cc.cc_company_name,
        cp.cp_type,
        i.i_item_sk AS item_sk
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN reason r2 ON cr.cr_reason_sk = r2.r_reason_sk
    WHERE
        cc.cc_state = 'CA'
        AND i.i_category = 'Electronics'
        AND cd.cd_gender = 'M'
        AND ca.ca_city = 'NEW YORK'
        AND sr.sr_return_quantity > 5
        AND cr.cr_return_amount > 100
        AND NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr_no
            WHERE cr_no.cr_call_center_sk = cc.cc_call_center_sk
              AND cr_no.cr_returned_date_sk = sr.sr_returned_date_sk
              AND cr_no.cr_item_sk <> i.i_item_sk
        )
)
SELECT
    main.c_customer_id,
    main.i_item_id,
    main.i_category,
    main.c_birth_month,
    main.cd_gender,
    main.ca_city,
    main.r_reason_desc,
    main.cc_company_name,
    main.cp_type,
    main.sr_return_quantity,
    (main.store_net_loss + main.catalog_net_loss) AS total_net_loss,
    cr_stats.avg_return_amount_for_item,
    sr_counts.total_store_returns_for_customer,
    RANK() OVER (PARTITION BY main.cc_company_name ORDER BY (main.store_net_loss + main.catalog_net_loss) DESC) AS loss_rank
FROM main
CROSS JOIN LATERAL (
    SELECT COUNT(*) AS total_store_returns_for_customer
    FROM store_returns sr2
    WHERE sr2.sr_customer_sk = main.customer_sk
) AS sr_counts
CROSS JOIN LATERAL (
    SELECT AVG(cr_sub.cr_return_amount) AS avg_return_amount_for_item
    FROM catalog_returns cr_sub
    WHERE cr_sub.cr_item_sk = main.item_sk
) AS cr_stats
ORDER BY loss_rank ASC, total_net_loss DESC
LIMIT 100
