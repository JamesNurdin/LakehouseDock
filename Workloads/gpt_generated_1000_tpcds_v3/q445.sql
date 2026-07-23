WITH base AS (
    SELECT
        s.s_store_id AS s_store_id,
        s.s_state AS s_state,
        i.i_brand AS i_brand,
        d.d_year AS d_year,
        cc.cc_market_manager AS cc_market_manager,
        r.r_reason_desc AS r_reason_desc,
        sr.sr_return_quantity AS sr_qty,
        sr.sr_return_amt AS sr_amt,
        sr.sr_net_loss AS sr_net_loss,
        cr.cr_return_quantity AS cr_qty,
        cr.cr_return_amount AS cr_amt,
        cr.cr_net_loss AS cr_net_loss
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returning_customer_sk = c.c_customer_sk
        AND cr.cr_returning_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE
        d.d_year = 2001
        AND i.i_brand = 'Brand#12'
        AND s.s_state = 'CA'
        AND cc.cc_market_manager = 'John Melendez'
        AND sr.sr_net_loss > 50
        AND EXISTS (
            SELECT 1
            FROM web_page wp
            WHERE wp.wp_customer_sk = c.c_customer_sk
              AND wp.wp_creation_date_sk = d.d_date_sk
              AND wp.wp_autogen_flag = 'Y'
              AND wp.wp_type = 'Home'
        )
)
SELECT
    s_store_id,
    s_state,
    i_brand,
    d_year,
    cc_market_manager,
    r_reason_desc,
    SUM(sr_qty) AS total_store_return_qty,
    SUM(cr_qty) AS total_catalog_return_qty,
    SUM(sr_amt) + SUM(cr_amt) AS total_return_amount,
    AVG(sr_net_loss) AS avg_store_net_loss,
    AVG(cr_net_loss) AS avg_catalog_net_loss,
    COUNT(*) AS total_transactions
FROM base
GROUP BY
    s_store_id,
    s_state,
    i_brand,
    d_year,
    cc_market_manager,
    r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
