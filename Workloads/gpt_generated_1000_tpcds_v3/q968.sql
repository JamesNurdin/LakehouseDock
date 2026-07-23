WITH promo_returns AS (
    SELECT
        p.p_promo_id,
        d.d_year,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        AVG(sr.sr_return_quantity) AS avg_return_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    GROUP BY p.p_promo_id, d.d_year
)
SELECT
    cc.cc_name,
    cc.cc_state,
    cd.cd_gender,
    hd.hd_buy_potential,
    wp.wp_url,
    p.p_promo_name,
    d.d_year,
    pr.total_return_amt,
    RANK() OVER (PARTITION BY d.d_year ORDER BY pr.total_return_amt DESC) AS return_rank,
    CASE 
        WHEN hd.hd_buy_potential = '>10000' THEN 'High Potential'
        WHEN hd.hd_buy_potential = '5001-10000' THEN 'Medium Potential'
        ELSE 'Low Potential'
    END AS hd_potential_category,
    (SELECT SUM(sr2.sr_return_amt)
     FROM store_returns sr2
     WHERE sr2.sr_hdemo_sk = sr.sr_hdemo_sk) AS household_total_return,
    CASE WHEN EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = wp.wp_customer_sk
          AND wp2.wp_char_count > 5000
    ) THEN 1 ELSE 0 END AS high_char_page_exists
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
JOIN promo_returns pr ON pr.p_promo_id = p.p_promo_id AND pr.d_year = d.d_year
WHERE d.d_year = 2000
  AND cc.cc_state = 'CA'
  AND cd.cd_gender = 'M'
  AND hd.hd_buy_potential = '>10000'
  AND wp.wp_char_count BETWEEN 2000 AND 5000
ORDER BY d.d_year, return_rank, cc.cc_name
LIMIT 100
