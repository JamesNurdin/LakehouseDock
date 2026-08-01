WITH
  sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_quantity > 1
      AND cs_ext_ship_cost > 100
      AND cs_net_paid_inc_ship > 500
      AND cs_ship_addr_sk IN (934106, 1669662, 1419986, 3405652, 5139470)
  ),
  joined AS (
    SELECT
      ss.cs_order_number,
      ss.cs_ship_addr_sk,
      ss.cs_ext_ship_cost,
      ss.cs_net_paid_inc_ship,
      ss.cs_quantity,
      p.p_promo_id,
      p.p_purpose,
      p.p_channel_event
    FROM sampled_sales ss
    LEFT JOIN promotion p
      ON ss.cs_promo_sk = p.p_promo_sk
    WHERE (p.p_purpose = 'Unknown' OR p.p_purpose IS NULL)
      AND (p.p_channel_event = 'N' OR p.p_channel_event IS NULL)
  ),
  unioned AS (
    SELECT cs_order_number, cs_ship_addr_sk, cs_ext_ship_cost, cs_net_paid_inc_ship, cs_quantity, p_promo_id
    FROM joined
    WHERE cs_ext_ship_cost > 200
    UNION
    SELECT cs_order_number, cs_ship_addr_sk, cs_ext_ship_cost, cs_net_paid_inc_ship, cs_quantity, p_promo_id
    FROM joined
    WHERE cs_quantity >= 5
  ),
  ranked AS (
    SELECT
      u.*,
      ROW_NUMBER() OVER (PARTITION BY cs_ship_addr_sk ORDER BY cs_net_paid_inc_ship DESC) AS rn_ship,
      RANK() OVER (ORDER BY cs_ext_ship_cost DESC) AS rank_cost
    FROM unioned u
  ),
  final AS (
    SELECT
      r.cs_order_number,
      r.cs_ship_addr_sk,
      r.cs_ext_ship_cost,
      r.cs_net_paid_inc_ship,
      r.cs_quantity,
      r.p_promo_id,
      r.rn_ship,
      r.rank_cost,
      (
        SELECT COUNT(*)
        FROM promotion p2
        WHERE p2.p_promo_id = r.p_promo_id
      ) AS promo_count,
      CASE
        WHEN EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_order_number = r.cs_order_number
            AND cs2.cs_quantity > 10
        ) THEN 'HIGH_QTY'
        ELSE 'NORMAL_QTY'
      END AS qty_flag,
      la.avg_net_paid_ship_addr
    FROM ranked r
    LEFT JOIN LATERAL (
      SELECT AVG(cs_net_paid_inc_ship) AS avg_net_paid_ship_addr
      FROM catalog_sales cs3
      WHERE cs3.cs_ship_addr_sk = r.cs_ship_addr_sk
    ) la ON TRUE
    WHERE r.rn_ship = 1
  )
SELECT *
FROM final
EXCEPT
SELECT *
FROM final
WHERE rank_cost > 10
LIMIT 100
