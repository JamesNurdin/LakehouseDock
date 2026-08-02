WITH returning_data AS (
    SELECT
        ca.ca_county AS county,
        cd.cd_credit_rating AS credit_rating,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN customer_address ca
        ON wr.wr_returning_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating IN (
        SELECT DISTINCT cd2.cd_credit_rating
        FROM customer_demographics cd2
        WHERE cd2.cd_purchase_estimate > 5000
    )
      AND wr.wr_return_quantity > 0
    GROUP BY ca.ca_county, cd.cd_credit_rating
),
refunded_data AS (
    SELECT
        ca.ca_county AS county,
        cd.cd_credit_rating AS credit_rating,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_refunded_cdemo_sk = cd.cd_demo_sk
          AND wr2.wr_return_quantity > 5
    )
      AND wr.wr_return_quantity > 0
    GROUP BY ca.ca_county, cd.cd_credit_rating
)
SELECT
    i.county,
    CASE
        WHEN (SELECT SUM(rd.total_net_loss) FROM returning_data rd WHERE rd.county = i.county) >
             (SELECT SUM(fd.total_net_loss) FROM refunded_data fd WHERE fd.county = i.county)
        THEN 'RETURNING_HIGHER'
        ELSE 'REFUNDED_HIGHER'
    END AS net_loss_comparison,
    (SELECT COUNT(DISTINCT rd.credit_rating)
     FROM returning_data rd
     WHERE rd.county = i.county) AS distinct_returning_credit_ratings
FROM (
    SELECT county FROM returning_data
    INTERSECT
    SELECT county FROM refunded_data
) AS i
ORDER BY distinct_returning_credit_ratings DESC, i.county
LIMIT 100
