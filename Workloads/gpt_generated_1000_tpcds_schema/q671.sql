WITH page_promotions AS (
    SELECT
        cp.cp_catalog_page_id,
        p.p_promo_id,
        cp.cp_description,
        p.p_promo_name
    FROM catalog_page cp
    FULL OUTER JOIN promotion p
        ON cp.cp_start_date_sk = p.p_start_date_sk
       AND cp.cp_end_date_sk = p.p_end_date_sk
)
SELECT
    i.c_customer_id,
    i.return_date,
    i.net_loss,
    pp.cp_catalog_page_id,
    pp.p_promo_id,
    pp.cp_description,
    pp.p_promo_name
FROM (
    SELECT
        c.c_customer_id,
        d.d_date AS return_date,
        sr.sr_net_loss AS net_loss
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM reason r
          WHERE r.r_reason_sk = sr.sr_reason_sk
            AND r.r_reason_desc LIKE '%warranty%'
      )
    INTERSECT
    SELECT
        c.c_customer_id,
        d.d_date AS return_date,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM reason r
          WHERE r.r_reason_sk = wr.wr_reason_sk
            AND r.r_reason_desc LIKE '%warranty%'
      )
) AS i
LEFT JOIN page_promotions pp
    ON pp.cp_description IS NOT NULL
ORDER BY i.c_customer_id
LIMIT 100
