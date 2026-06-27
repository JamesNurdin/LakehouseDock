/*
   Analytical query: total net loss by return reason across the three return channels
   (store, catalog, web) together with a weighted average birth year of the
   customers who received the refunds.  The query respects the allowed join
   rules and uses only the selected tables.
*/
WITH combined AS (
    -- Catalog returns
    SELECT
        r.r_reason_desc   AS reason_desc,
        cr.cr_net_loss    AS net_loss,
        c.c_birth_year    AS birth_year,
        'catalog'         AS channel
    FROM catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk

    UNION ALL

    -- Store returns
    SELECT
        r.r_reason_desc   AS reason_desc,
        sr.sr_net_loss    AS net_loss,
        c.c_birth_year    AS birth_year,
        'store'           AS channel
    FROM store_returns sr
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk

    UNION ALL

    -- Web returns
    SELECT
        r.r_reason_desc   AS reason_desc,
        wr.wr_net_loss    AS net_loss,
        c.c_birth_year    AS birth_year,
        'web'             AS channel
    FROM web_returns wr
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
)
SELECT
    reason_desc,
    SUM(CASE WHEN channel = 'store'   THEN net_loss ELSE 0 END)   AS store_net_loss,
    SUM(CASE WHEN channel = 'catalog' THEN net_loss ELSE 0 END)   AS catalog_net_loss,
    SUM(CASE WHEN channel = 'web'     THEN net_loss ELSE 0 END)   AS web_net_loss,
    SUM(net_loss)                                                AS total_net_loss,
    CASE
        WHEN SUM(net_loss) = 0 THEN NULL
        ELSE SUM(birth_year * net_loss) / SUM(net_loss)
    END                                                          AS weighted_avg_birth_year
FROM combined
GROUP BY reason_desc
ORDER BY total_net_loss DESC
LIMIT 10
