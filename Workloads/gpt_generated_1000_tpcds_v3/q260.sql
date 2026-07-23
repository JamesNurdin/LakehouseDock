WITH date_filtered AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_year = 2002
      AND d_week_seq BETWEEN 6 AND 15
),
aggregated_returns AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        r.r_reason_desc,
        SUM(sr.sr_net_loss) AS total_store_net_loss,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_count,
        i.i_item_sk
    FROM store_returns sr
    JOIN date_filtered d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE 
        i.i_brand = 'Brand#12'
        AND i.i_category = 'Sports'
        AND ca.ca_state = 'CA'
        AND cp.cp_type = 'Electronic'
        AND cc.cc_state = 'CA'
        AND sr.sr_net_loss > 0
        AND cr.cr_net_loss > 0
        AND sr.sr_return_quantity > 1
        AND cr.cr_return_quantity > 1
    GROUP BY 
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        r.r_reason_desc,
        i.i_item_sk
)
SELECT
    ar.i_item_id,
    ar.i_product_name,
    ar.i_brand,
    ar.i_category,
    ar.r_reason_desc,
    ar.total_store_net_loss,
    ar.total_catalog_net_loss,
    ar.store_return_count,
    ar.catalog_return_count,
    ROW_NUMBER() OVER (
        PARTITION BY ar.i_brand 
        ORDER BY (ar.total_store_net_loss + ar.total_catalog_net_loss) DESC
    ) AS brand_return_rank,
    CASE 
        WHEN (ar.total_store_net_loss + ar.total_catalog_net_loss) > 1000 THEN 'High Loss'
        ELSE 'Low Loss'
    END AS loss_category,
    (
        SELECT COUNT(DISTINCT sr2.sr_customer_sk)
        FROM store_returns sr2
        JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2002
          AND sr2.sr_item_sk = ar.i_item_sk
    ) AS distinct_customer_count
FROM aggregated_returns ar
WHERE (ar.total_store_net_loss + ar.total_catalog_net_loss) > 500
ORDER BY ar.total_store_net_loss DESC
LIMIT 100
