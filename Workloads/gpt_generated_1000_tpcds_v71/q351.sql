WITH returns_detail AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_return_amt,
        sr.sr_fee,
        sr.sr_reversed_charge,
        sr.sr_store_credit,
        sr.sr_net_loss,
        cd.cd_credit_rating,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sr.sr_return_amt > 50
      AND ib.ib_upper_bound <= 50000
)
SELECT
    rd.sr_ticket_number,
    rd.sr_return_amt,
    rd.cd_credit_rating,
    rd.r_reason_desc,
    (
        SELECT avg(inner_rd.sr_return_amt)
        FROM returns_detail inner_rd
        WHERE inner_rd.cd_credit_rating = rd.cd_credit_rating
    ) AS avg_return_by_credit
FROM returns_detail rd
WHERE rd.cd_credit_rating = 'Low Risk'
  AND rd.hd_buy_potential = '0-500'

UNION ALL

SELECT
    rd.sr_ticket_number,
    rd.sr_return_amt,
    rd.cd_credit_rating,
    rd.r_reason_desc,
    (
        SELECT avg(inner_rd.sr_return_amt)
        FROM returns_detail inner_rd
        WHERE inner_rd.r_reason_desc = rd.r_reason_desc
    ) AS avg_return_by_reason
FROM returns_detail rd
WHERE rd.r_reason_desc = 'Damaged'
  AND rd.sr_fee > 20

ORDER BY sr_return_amt DESC
LIMIT 100
