WITH joined AS (
  SELECT
    s.s_store_id               AS s_store_id,
    s.s_state                  AS s_state,
    i.i_item_id                AS i_item_id,
    i.i_brand                  AS i_brand,
    cr.cr_return_amount        AS cr_return_amount,
    cr.cr_return_ship_cost     AS cr_return_ship_cost,
    sr.sr_return_amt           AS sr_return_amt,
    wr.wr_return_amt           AS wr_return_amt,
    r.r_reason_sk              AS r_reason_sk,
    r.r_reason_desc            AS r_reason_desc,
    cp.cp_type                 AS cp_type,
    p.p_discount_active        AS p_discount_active,
    td.t_hour                  AS t_hour
  FROM store_sales ss
  JOIN time_dim td               ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN item i                    ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c                ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca       ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd  ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN store s                   ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p               ON ss.ss_promo_sk = p.p_promo_sk
  JOIN catalog_returns cr        ON cr.cr_item_sk = i.i_item_sk
  JOIN catalog_page cp           ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm              ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN reason r                  ON cr.cr_reason_sk = r.r_reason_sk
  JOIN store_returns sr          ON sr.sr_item_sk = ss.ss_item_sk
                                 AND sr.sr_ticket_number = ss.ss_ticket_number
                                 AND sr.sr_store_sk = s.s_store_sk
  JOIN web_returns wr           ON wr.wr_item_sk = i.i_item_sk
                                 AND wr.wr_returned_time_sk = td.t_time_sk
  WHERE cp.cp_type = 'monthly'
    AND i.i_brand = 'Brand#12'
    AND p.p_discount_active = 'Y'
    AND s.s_state = 'CA'
    AND r.r_reason_desc LIKE '%damaged%'
    AND cr.cr_return_ship_cost > 100
    AND td.t_hour BETWEEN 9 AND 17
),
aggregated AS (
  SELECT
    s_store_id,
    s_state,
    i_item_id,
    i_brand,
    r_reason_sk,
    r_reason_desc,
    SUM(cr_return_amount)               AS total_catalog_return_amount,
    SUM(sr_return_amt)                  AS total_store_return_amount,
    SUM(wr_return_amt)                  AS total_web_return_amount,
    CASE WHEN SUM(cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS catalog_return_level,
    SUM(cr_return_amount) + SUM(sr_return_amt) + SUM(wr_return_amt) AS total_return_amount
  FROM joined
  GROUP BY
    s_store_id,
    s_state,
    i_item_id,
    i_brand,
    r_reason_sk,
    r_reason_desc
)
SELECT
  s_store_id,
  s_state,
  i_item_id,
  i_brand,
  total_catalog_return_amount,
  total_store_return_amount,
  total_web_return_amount,
  catalog_return_level,
  total_return_amount,
  RANK() OVER (PARTITION BY s_state ORDER BY total_return_amount DESC) AS state_return_rank,
  (SELECT AVG(cr2.cr_return_amount)
     FROM catalog_returns cr2
    WHERE cr2.cr_reason_sk = aggregated.r_reason_sk) AS avg_return_amount_by_reason
FROM aggregated
ORDER BY total_return_amount DESC, s_store_id
LIMIT 100
