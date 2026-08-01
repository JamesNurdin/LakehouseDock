WITH
  sr_agg AS (
    SELECT
      sr.sr_item_sk AS item_sk,
      d.d_date,
      i.i_category,
      SUM(sr.sr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
    GROUP BY sr.sr_item_sk, d.d_date, i.i_category
  ),
  wr_agg AS (
    SELECT
      wr.wr_item_sk AS item_sk,
      d.d_date,
      i.i_category,
      SUM(wr.wr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
    GROUP BY wr.wr_item_sk, d.d_date, i.i_category
  ),
  returns_union AS (
    SELECT * FROM sr_agg
    UNION ALL
    SELECT * FROM wr_agg
  ),
  promo_details AS (
    SELECT
      p.p_promo_id,
      i.i_item_sk,
      p.p_discount_active,
      channel_detail
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    CROSS JOIN UNNEST(split(p.p_channel_details, ',')) AS t(channel_detail)
    WHERE p.p_channel_email = 'Y'
  ),
  inv_item AS (
    SELECT
      inv.inv_date_sk,
      inv.inv_item_sk,
      inv.inv_quantity_on_hand,
      i.i_item_sk,
      i.i_category
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_month_seq = 12
  ),
  promo_inv_full AS (
    SELECT
      pd.p_promo_id,
      pd.i_item_sk,
      pd.p_discount_active,
      pd.channel_detail,
      ii.inv_quantity_on_hand,
      ii.inv_date_sk
    FROM promo_details pd
    FULL OUTER JOIN inv_item ii ON pd.i_item_sk = ii.i_item_sk
  )
SELECT
  d.d_date,
  ws.web_name,
  cc.cc_name,
  pi.p_promo_id,
  pi.channel_detail,
  pi.inv_quantity_on_hand,
  ru.i_category,
  ru.total_return_amt,
  ru.return_cnt,
  CASE WHEN ru.total_return_amt > 1000 THEN 'High' ELSE 'Low' END AS return_level,
  ROW_NUMBER() OVER (PARTITION BY ru.i_category ORDER BY ru.total_return_amt DESC) AS rn_category,
  (SELECT AVG(total_return_amt) FROM returns_union) AS avg_return_amt_overall
FROM returns_union ru
JOIN date_dim d ON ru.d_date = d.d_date
LEFT JOIN promo_inv_full pi ON ru.item_sk = pi.i_item_sk
LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
WHERE ws.web_state = 'CA'
  AND cc.cc_state = 'CA'
  AND pi.p_discount_active = 'Y'
ORDER BY ru.total_return_amt DESC
LIMIT 100
