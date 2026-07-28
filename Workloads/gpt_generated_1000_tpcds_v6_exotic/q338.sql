WITH
    filtered_ship AS (
        SELECT
            sm_ship_mode_sk,
            sm_ship_mode_id,
            sm_carrier,
            sm_contract,
            regexp_extract(sm_contract, '([0-9]+)', 1) AS contract_number,
            CASE
                WHEN regexp_like(sm_contract, '^[A-Z]{2}[0-9]') THEN 'pattern_a'
                ELSE 'other'
            END AS contract_pattern
        FROM ship_mode
        WHERE sm_carrier LIKE 'D%'
          AND regexp_like(sm_contract, '[0-9]{3}')
    ),
    agg_returns AS (
        SELECT
            f.sm_ship_mode_sk,
            f.sm_ship_mode_id,
            f.sm_carrier,
            f.contract_number,
            f.contract_pattern,
            COUNT(cr.cr_order_number) AS total_returns,
            SUM(cr.cr_return_amount) AS total_return_amount,
            AVG(cr.cr_fee) AS avg_fee,
            SUM(cr.cr_net_loss) AS total_net_loss,
            SUM(CASE WHEN cr.cr_return_amount > 100 THEN 1 ELSE 0 END) AS high_amount_returns,
            CONCAT(f.sm_carrier, '_', f.sm_ship_mode_id) AS carrier_mode_key
        FROM filtered_ship f
        JOIN catalog_returns cr
          ON cr.cr_ship_mode_sk = f.sm_ship_mode_sk
        WHERE cr.cr_return_ship_cost > 1000
        GROUP BY
            f.sm_ship_mode_sk,
            f.sm_ship_mode_id,
            f.sm_carrier,
            f.contract_number,
            f.contract_pattern
    )
SELECT
    sm_ship_mode_id,
    sm_carrier,
    contract_number,
    contract_pattern,
    total_returns,
    total_return_amount,
    avg_fee,
    total_net_loss,
    high_amount_returns,
    carrier_mode_key,
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM agg_returns
ORDER BY total_net_loss DESC
LIMIT 100
