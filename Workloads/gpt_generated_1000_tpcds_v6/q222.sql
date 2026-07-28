WITH store_ret AS (
    SELECT DISTINCT
        i.i_item_id,
        d.d_date AS return_date,
        'store' AS channel,
        sr.sr_return_quantity AS return_quantity,
        sr.sr_return_amt AS return_amount,
        (
            SELECT avg(cr.cr_return_amount)
            FROM catalog_returns cr
            WHERE cr.cr_item_sk = i.i_item_sk
        ) AS catalog_avg_return_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_item_sk = i.i_item_sk
            AND cr.cr_returned_date_sk = d.d_date_sk
      )
),
web_ret AS (
    SELECT DISTINCT
        i.i_item_id,
        d.d_date AS return_date,
        'web' AS channel,
        wr.wr_return_quantity AS return_quantity,
        wr.wr_return_amt AS return_amount,
        (
            SELECT avg(cr.cr_return_amount)
            FROM catalog_returns cr
            WHERE cr.cr_item_sk = i.i_item_sk
        ) AS catalog_avg_return_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2002
      AND wp.wp_type = 'content'
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_item_sk = i.i_item_sk
            AND cr.cr_returned_date_sk = d.d_date_sk
      )
)
SELECT * FROM store_ret
UNION ALL
SELECT * FROM web_ret
ORDER BY return_date DESC, i_item_id
