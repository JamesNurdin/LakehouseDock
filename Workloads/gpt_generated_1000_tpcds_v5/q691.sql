WITH filtered AS (
    SELECT
        wr.wr_net_loss,
        cd.cd_gender,
        cd.cd_credit_rating,
        hd.hd_buy_potential
    FROM web_returns wr
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(cd.cd_credit_rating, '^A[0-9]+$')
      AND hd.hd_buy_potential LIKE '%1000%'
)
SELECT
    substring(cd_gender, 1, 1) AS gender_initial,
    hd_buy_potential,
    regexp_extract(cd_credit_rating, '([0-9]+)', 1) AS credit_digits,
    sum(wr_net_loss) AS total_net_loss,
    count(*) AS returns_cnt
FROM filtered
GROUP BY
    substring(cd_gender, 1, 1),
    hd_buy_potential,
    regexp_extract(cd_credit_rating, '([0-9]+)', 1)
ORDER BY total_net_loss DESC
LIMIT 100
