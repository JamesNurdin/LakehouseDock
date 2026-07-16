WITH address_agg AS (
    SELECT ca_state,
           ca_county,
           COUNT(*) AS addr_cnt,
           AVG(ca_gmt_offset) AS avg_offset,
           COUNT(DISTINCT ca_zip) AS distinct_zips
    FROM customer_address
    WHERE ca_country = 'United States'
      AND ca_state IS NOT NULL
    GROUP BY ca_state, ca_county
),
ship_agg AS (
    SELECT sm_carrier,
           sm_type,
           COUNT(*) AS ship_cnt,
           COUNT(DISTINCT sm_code) AS distinct_codes,
           MAX(sm_contract) FILTER (WHERE sm_contract IS NOT NULL) AS max_contract
    FROM ship_mode
    WHERE sm_carrier IS NOT NULL
    GROUP BY sm_carrier, sm_type
),
joined AS (
    SELECT a.ca_state,
           a.ca_county,
           a.addr_cnt,
           a.avg_offset,
           a.distinct_zips,
           s.sm_carrier,
           s.sm_type,
           s.ship_cnt,
           s.distinct_codes,
           s.max_contract,
           ROW_NUMBER() OVER (PARTITION BY a.ca_state ORDER BY s.ship_cnt DESC) AS ship_mode_rank_in_state,
           RANK() OVER (ORDER BY a.addr_cnt DESC) AS state_address_rank
    FROM address_agg a
    CROSS JOIN ship_agg s
    WHERE a.addr_cnt > 5
      AND s.ship_cnt > 2
)
SELECT ca_state,
       ca_county,
       addr_cnt,
       avg_offset,
       distinct_zips,
       sm_carrier,
       sm_type,
       ship_cnt,
       distinct_codes,
       max_contract,
       ship_mode_rank_in_state,
       state_address_rank
FROM joined
WHERE ship_mode_rank_in_state <= 3
ORDER BY state_address_rank, ship_mode_rank_in_state
