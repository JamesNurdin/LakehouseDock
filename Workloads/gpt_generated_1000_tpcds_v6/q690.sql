WITH base AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_year,
        ca.ca_state,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cr.cr_return_amount,
        cr.cr_net_loss,
        sr.sr_return_amt,
        sr.sr_net_loss,
        w.w_warehouse_name,
        wp.wp_type,
        COALESCE(cr.cr_net_loss, 0) + COALESCE(sr.sr_net_loss, 0) AS total_net_loss
    FROM catalog_returns cr
    INNER JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    INNER JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    INNER JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    INNER JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    INNER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT OUTER JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
    LEFT OUTER JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1960 AND 1970
      AND ca.ca_state IN ('CA', 'TX', 'NY')
      AND hd.hd_buy_potential = '5001-10000'
      AND ib.ib_lower_bound >= 50000
      AND cr.cr_return_amount > 100
      AND sr.sr_return_amt IS NOT NULL
      AND cr.cr_return_quantity > 0
), filtered AS (
    SELECT
        ca_state,
        wp_type,
        c_customer_sk,
        total_net_loss
    FROM base b
    WHERE EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = b.c_customer_sk
          AND sr2.sr_net_loss > 200
    )
)
SELECT
    ca_state,
    wp_type,
    COUNT(DISTINCT c_customer_sk) AS num_customers,
    SUM(total_net_loss) AS sum_net_loss,
    AVG(total_net_loss) AS avg_net_loss
FROM filtered
GROUP BY ca_state, wp_type
HAVING SUM(total_net_loss) > 500
ORDER BY sum_net_loss DESC
LIMIT 100
