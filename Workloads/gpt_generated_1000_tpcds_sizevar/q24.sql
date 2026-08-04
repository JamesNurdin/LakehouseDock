WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        cp.cp_catalog_page_id,
        cp.cp_type,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        td.t_hour,
        td.t_sub_shift,
        ca.ca_state,
        wr.wr_return_amt,
        wp.wp_url,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY cr.cr_return_amount DESC) AS store_return_rank
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN store_returns sr
        ON sr.sr_return_time_sk = td.t_time_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE cp.cp_type = 'catalog'
      AND td.t_sub_shift = 'morning'
      AND wr.wr_return_amt > 100
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_store_sk = s.s_store_sk
            AND sr2.sr_return_amt > 200
      )
)
SELECT
    s_store_id,
    s_store_name,
    s_state,
    cp_catalog_page_id,
    cr_return_amount,
    cr_return_quantity,
    t_hour,
    t_sub_shift,
    ca_state,
    wr_return_amt,
    wp_url,
    store_return_rank
FROM base
WHERE store_return_rank <= 5
ORDER BY s_store_name, store_return_rank
