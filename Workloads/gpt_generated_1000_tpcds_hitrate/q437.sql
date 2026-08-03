WITH item_words AS (
    SELECT
        i_item_sk,
        word,
        ROW_NUMBER() OVER (PARTITION BY i_item_sk ORDER BY word) AS word_seq
    FROM
        item
        CROSS JOIN UNNEST(split(i_item_desc, ' ')) AS t(word)
)
,
first_branch AS (
    SELECT
        cr.cr_order_number            AS order_number,
        cr.cr_return_amount           AS return_amount,
        cr.cr_return_quantity         AS return_quantity,
        cr.cr_returned_date_sk        AS returned_date_sk,
        d.d_year                      AS year,
        i.i_item_id                   AS item_id,
        c_ref.c_customer_id           AS customer_id,
        CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS amount_category,
        RANK() OVER (PARTITION BY d.d_year ORDER BY cr.cr_return_amount DESC) AS yearly_return_rank,
        iw.word_seq,
        iw.word
    FROM
        catalog_returns cr
        JOIN date_dim d                     ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i                         ON cr.cr_item_sk = i.i_item_sk
        JOIN customer c_ref                 ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
        JOIN customer_demographics cd_ref   ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
        JOIN household_demographics hd_ref  ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
        JOIN income_band ib_ref             ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
        JOIN call_center cc                 ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN web_page wp                    ON wp.wp_customer_sk = c_ref.c_customer_sk
        JOIN web_site ws                    ON ws.web_open_date_sk = d.d_date_sk
        JOIN inventory inv                  ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
        JOIN item_words iw                  ON iw.i_item_sk = i.i_item_sk
    WHERE
        d.d_year = 2001
        AND cc.cc_state = 'CA'
        AND ws.web_state = 'CA'
        AND cr.cr_return_amount IS NOT NULL
        AND cr.cr_return_quantity > 0
        AND i.i_current_price > 10
        AND cr.cr_order_number NOT IN (SELECT sr_ticket_number FROM store_returns)
)
,
second_branch AS (
    SELECT
        sr.sr_ticket_number            AS order_number,
        sr.sr_return_amt                AS return_amount,
        sr.sr_return_quantity           AS return_quantity,
        sr.sr_returned_date_sk          AS returned_date_sk,
        d.d_year                        AS year,
        i.i_item_id                     AS item_id,
        c.c_customer_id                 AS customer_id,
        CASE WHEN sr.sr_return_amt > 100 THEN 'High' ELSE 'Low' END AS amount_category,
        DENSE_RANK() OVER (PARTITION BY d.d_year ORDER BY sr.sr_return_amt DESC) AS yearly_return_rank,
        iw.word_seq,
        iw.word
    FROM
        store_returns sr
        JOIN date_dim d               ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i                   ON sr.sr_item_sk = i.i_item_sk
        JOIN customer c               ON sr.sr_customer_sk = c.c_customer_sk
        JOIN store s                  ON sr.sr_store_sk = s.s_store_sk
        JOIN inventory inv            ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
        JOIN item_words iw            ON iw.i_item_sk = i.i_item_sk
    WHERE
        d.d_year = 2001
        AND s.s_state = 'CA'
        AND i.i_current_price > 10
        AND sr.sr_ticket_number NOT IN (SELECT cr_order_number FROM catalog_returns)
)
SELECT
    order_number,
    return_amount,
    return_quantity,
    returned_date_sk,
    year,
    item_id,
    customer_id,
    amount_category,
    yearly_return_rank,
    word_seq,
    word
FROM (
    SELECT * FROM first_branch
    UNION DISTINCT
    SELECT * FROM second_branch
) AS unified
ORDER BY
    order_number,
    year DESC,
    amount_category
LIMIT 100
