WITH combined AS (
    -- Store returns for CA stores with high net loss, excluding items sold online
    SELECT
        'store' AS return_type,
        i.i_item_id,
        i.i_item_desc,
        sr.sr_returned_date_sk AS return_date_sk,
        sr.sr_net_loss AS return_amount,
        r.r_reason_desc
    FROM tpcds.store_returns sr
    JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.item i ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE s.s_state = 'CA'
      AND sr.sr_net_loss > 10
      AND NOT EXISTS (
          SELECT 1
          FROM tpcds.web_sales ws
          WHERE ws.ws_item_sk = sr.sr_item_sk
            AND ws.ws_sold_date_sk = sr.sr_returned_date_sk
      )
    UNION ALL
    -- Catalog returns for selected catalog pages with large return amount
    SELECT
        'catalog' AS return_type,
        i.i_item_id,
        i.i_item_desc,
        cr.cr_returned_date_sk AS return_date_sk,
        cr.cr_return_amount AS return_amount,
        r.r_reason_desc
    FROM tpcds.catalog_returns cr
    JOIN tpcds.item i ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_catalog_number IN (15, 16, 17)
      AND cr.cr_return_amount > 100
)
SELECT
    return_type,
    i_item_id,
    i_item_desc,
    SUM(return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    (SELECT AVG(cr_return_amount) FROM tpcds.catalog_returns) AS avg_catalog_return_amount
FROM combined
GROUP BY return_type, i_item_id, i_item_desc
HAVING SUM(return_amount) > 200
ORDER BY total_return_amount DESC
