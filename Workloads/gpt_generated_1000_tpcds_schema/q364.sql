WITH
    intersect_keys AS (
        SELECT sr.sr_ticket_number AS key
        FROM store_returns sr
        JOIN date_dim d1 ON sr.sr_returned_date_sk = d1.d_date_sk
        WHERE d1.d_year = 2001
        INTERSECT
        SELECT cr.cr_order_number AS key
        FROM catalog_returns cr
        JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
    ),
    union_keys AS (
        SELECT sr.sr_customer_sk AS key
        FROM store_returns sr
        UNION
        SELECT wr.wr_refunded_customer_sk AS key
        FROM web_returns wr
    ),
    main AS (
        SELECT
            d_store.d_year,
            COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
            SUM(CASE WHEN sr.sr_net_loss > 0 THEN sr.sr_net_loss ELSE 0 END) AS total_store_net_loss,
            SUM(cr.cr_net_loss) AS total_catalog_net_loss,
            SUM(wr.wr_net_loss) AS total_web_net_loss,
            SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
            COUNT(DISTINCT wh.w_warehouse_id) AS warehouse_cnt,
            COUNT(DISTINCT ws.web_site_id) AS website_cnt,
            ROW_NUMBER() OVER (PARTITION BY d_store.d_year ORDER BY SUM(cr.cr_net_loss) DESC) AS rn
        FROM store_returns sr
        JOIN date_dim d_store ON sr.sr_returned_date_sk = d_store.d_date_sk
        JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
        JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
        JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_store.d_date_sk
        JOIN customer_address ca_cr_ref ON cr.cr_refunded_addr_sk = ca_cr_ref.ca_address_sk
        JOIN customer_demographics cd_cr_ref ON cr.cr_refunded_cdemo_sk = cd_cr_ref.cd_demo_sk
        JOIN warehouse wh ON cr.cr_warehouse_sk = wh.w_warehouse_sk
        JOIN inventory inv ON inv.inv_date_sk = d_store.d_date_sk AND inv.inv_warehouse_sk = wh.w_warehouse_sk
        JOIN web_returns wr ON wr.wr_returned_date_sk = d_store.d_date_sk
        JOIN customer_address ca_wr_ref ON wr.wr_refunded_addr_sk = ca_wr_ref.ca_address_sk
        JOIN customer_demographics cd_wr_ref ON wr.wr_refunded_cdemo_sk = cd_wr_ref.cd_demo_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
        JOIN web_site ws ON ws.web_open_date_sk = d_store.d_date_sk
        WHERE d_store.d_year = 2001
          AND sr.sr_ticket_number IN (SELECT key FROM intersect_keys)
          AND sr.sr_customer_sk IN (SELECT key FROM union_keys)
        GROUP BY d_store.d_year
    )
SELECT
    m.d_year,
    m.store_return_cnt,
    m.total_store_net_loss,
    m.total_catalog_net_loss,
    m.total_web_net_loss,
    m.total_inventory_on_hand,
    m.warehouse_cnt,
    m.website_cnt,
    CASE WHEN m.total_store_net_loss > m.total_catalog_net_loss THEN 'Store higher' ELSE 'Catalog higher' END AS loss_comparison,
    m.rn AS rank_in_year
FROM main m
WHERE m.rn <= 5
ORDER BY m.d_year, m.rn
LIMIT 100
