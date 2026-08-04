WITH intersect_keys AS (
        SELECT cc_call_center_sk
        FROM call_center
        WHERE cc_state LIKE 'A%'
        INTERSECT
        SELECT cs_call_center_sk
        FROM catalog_sales
        WHERE cs_quantity > 10
    ),
    except_keys AS (
        SELECT cc_call_center_sk
        FROM call_center
        WHERE cc_city LIKE 'New%'
        EXCEPT
        SELECT cs_call_center_sk
        FROM catalog_sales
        WHERE cs_quantity < 5
    ),
    base AS (
        SELECT
            cc.cc_call_center_sk,
            cc.cc_name,
            cc.cc_manager,
            d.d_year,
            SUM(cs.cs_net_profit) AS total_profit,
            LAG(SUM(cs.cs_net_profit)) OVER (PARTITION BY cc.cc_call_center_sk ORDER BY d.d_year) AS prev_year_profit
        FROM catalog_sales cs
        JOIN date_dim d
            ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        WHERE cc.cc_call_center_sk IN (SELECT cc_call_center_sk FROM intersect_keys)
          AND cc.cc_call_center_sk NOT IN (
              SELECT cr_call_center_sk
              FROM catalog_returns
              WHERE cr_return_amount > 5000
          )
        GROUP BY cc.cc_call_center_sk, cc.cc_name, cc.cc_manager, d.d_year
        HAVING SUM(cs.cs_net_profit) > 10000
    )
SELECT
    b.cc_call_center_sk,
    b.cc_name,
    regexp_extract(b.cc_manager, '(\\w+)', 1) AS manager_first_name,
    substring(b.cc_name, 1, 5) AS name_prefix,
    b.d_year,
    b.total_profit,
    b.prev_year_profit,
    CASE
        WHEN b.prev_year_profit IS NULL THEN b.total_profit
        ELSE b.total_profit - b.prev_year_profit
    END AS profit_change
FROM base b
WHERE b.cc_call_center_sk IN (SELECT cc_call_center_sk FROM except_keys)
ORDER BY b.total_profit DESC
LIMIT 100
