WITH filtered_items AS (
    SELECT i_item_sk
    FROM item
    WHERE i_current_price > 150
    UNION
    SELECT i_item_sk
    FROM item
    WHERE i_brand = 'BrandX' AND i_current_price > 100
),

catalog_agg AS (
    SELECT
        cr.cr_returning_customer_sk AS c_customer_sk,
        cr.cr_item_sk AS i_item_sk,
        d_cat.d_year AS return_year,
        SUM(cr.cr_return_amount) AS total_cr_amount,
        SUM(cr.cr_net_loss) AS total_cr_net_loss,
        COUNT(*) AS cr_return_cnt,
        cr.cr_ship_mode_sk AS ship_mode_sk
    FROM catalog_returns cr
    JOIN date_dim d_cat ON cr.cr_returned_date_sk = d_cat.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        d_cat.d_year = 2001
        AND cr.cr_return_amount > 100
        AND cr.cr_net_loss > 0
        AND i.i_item_sk IN (SELECT i_item_sk FROM filtered_items)
        AND EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_item_sk = cr.cr_item_sk
              AND wr.wr_returning_customer_sk = cr.cr_returning_customer_sk
              AND wr.wr_return_amt > 50
        )
    GROUP BY
        cr.cr_returning_customer_sk,
        cr.cr_item_sk,
        d_cat.d_year,
        cr.cr_ship_mode_sk
),

web_agg AS (
    SELECT
        wr.wr_returning_customer_sk AS c_customer_sk,
        wr.wr_item_sk AS i_item_sk,
        d_web.d_year AS return_year,
        SUM(wr.wr_return_amt) AS total_wr_amount,
        SUM(wr.wr_net_loss) AS total_wr_net_loss,
        COUNT(*) AS wr_return_cnt
    FROM web_returns wr
    JOIN date_dim d_web ON wr.wr_returned_date_sk = d_web.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE
        d_web.d_year = 2001
        AND wr.wr_return_amt > 100
        AND i.i_item_sk IN (SELECT i_item_sk FROM filtered_items)
        AND i.i_brand = 'BrandY'
        AND EXISTS (
            SELECT 1
            FROM catalog_returns cr
            WHERE cr.cr_item_sk = wr.wr_item_sk
              AND cr.cr_returning_customer_sk = wr.wr_returning_customer_sk
              AND cr.cr_return_amount > 50
        )
    GROUP BY
        wr.wr_returning_customer_sk,
        wr.wr_item_sk,
        d_web.d_year
)

SELECT
    COALESCE(ca.c_customer_sk, wa.c_customer_sk) AS customer_sk,
    COALESCE(ca.i_item_sk, wa.i_item_sk) AS item_sk,
    COALESCE(ca.return_year, wa.return_year) AS return_year,
    ca.total_cr_amount,
    wa.total_wr_amount,
    ca.total_cr_net_loss,
    wa.total_wr_net_loss,
    ca.cr_return_cnt,
    wa.wr_return_cnt,
    sm.sm_type AS ship_mode_type,
    cu.c_first_name,
    cu.c_last_name,
    ROW_NUMBER() OVER (
        PARTITION BY COALESCE(ca.c_customer_sk, wa.c_customer_sk)
        ORDER BY (COALESCE(ca.total_cr_net_loss, 0) + COALESCE(wa.total_wr_net_loss, 0)) DESC
    ) AS rn,
    (COALESCE(ca.total_cr_net_loss, 0) + COALESCE(wa.total_wr_net_loss, 0)) AS total_net_loss_combined
FROM catalog_agg ca
FULL OUTER JOIN web_agg wa
    ON ca.c_customer_sk = wa.c_customer_sk
   AND ca.i_item_sk = wa.i_item_sk
   AND ca.return_year = wa.return_year
LEFT JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = ca.ship_mode_sk
LEFT JOIN customer cu
    ON cu.c_customer_sk = COALESCE(ca.c_customer_sk, wa.c_customer_sk)
WHERE (COALESCE(ca.total_cr_amount, 0) + COALESCE(wa.total_wr_amount, 0)) > 200
ORDER BY total_net_loss_combined DESC
LIMIT 100
