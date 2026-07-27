/*
  Goal:  Analyze total store and web returns for California customers in 1900, broken down by quarter, and classify the overall net loss as High or Low.
*/
WITH base AS (
    SELECT
        d.d_quarter_name,
        ca.ca_state,
        sr.sr_customer_sk,
        sr.sr_return_amt,
        wr.wr_return_amt,
        sr.sr_net_loss,
        wr.wr_net_loss
    FROM
        store_returns sr
        INNER JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        INNER JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        INNER JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        INNER JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        INNER JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        INNER JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        INNER JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    WHERE
        d.d_year = 1900
        AND ca.ca_state = 'CA'
        AND hd.hd_income_band_sk IN (2, 4, 5)
        AND cd.cd_gender = 'M'
        AND p.p_discount_active = 'Y'
        AND EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_promo_name = 'Holiday Sale'
              AND p2.p_start_date_sk = d.d_date_sk
        )
)
SELECT
    d_quarter_name,
    ca_state,
    COUNT(DISTINCT sr_customer_sk) AS distinct_store_customers,
    SUM(sr_return_amt) AS total_store_return_amt,
    SUM(wr_return_amt) AS total_web_return_amt,
    SUM(sr_net_loss + wr_net_loss) AS total_net_loss,
    CASE WHEN SUM(sr_net_loss + wr_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
FROM
    base
GROUP BY
    d_quarter_name,
    ca_state
ORDER BY
    d_quarter_name,
    ca_state
LIMIT 100
