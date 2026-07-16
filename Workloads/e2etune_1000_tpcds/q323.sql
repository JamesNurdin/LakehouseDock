WITH store_return_stats AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state AS store_state,
        ca.ca_county,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(*) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_quantity) AS avg_return_qty
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE ca.ca_country = 'United States'
      AND ca.ca_state IN ('AZ', 'CO', 'NM')
      AND ca.ca_gmt_offset IN (-7.00, -6.00, -5.00)
      AND cd.cd_gender = 'M'
      AND cd.cd_education_status = 'College'
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        ca.ca_county,
        cd.cd_gender,
        cd.cd_marital_status
    HAVING SUM(sr.sr_return_amt) > 1000
)
SELECT
    srs.s_store_name,
    srs.store_state,
    srs.ca_county,
    srs.cd_gender,
    srs.cd_marital_status,
    srs.total_returns,
    srs.total_return_amount,
    srs.total_net_loss,
    srs.avg_return_qty,
    RANK() OVER (PARTITION BY srs.store_state ORDER BY srs.total_net_loss DESC) AS store_state_rank
FROM store_return_stats srs
ORDER BY srs.total_net_loss DESC
LIMIT 20
