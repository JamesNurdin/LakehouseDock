WITH a AS (
    SELECT i.i_item_id,
           i.i_brand,
           t.t_shift
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE t.t_shift = 'first'
      AND cd.cd_credit_rating = 'Good'
    UNION
    SELECT i.i_item_id,
           i.i_brand,
           t.t_shift
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE t.t_shift = 'third'
      AND cd.cd_credit_rating = 'Low Risk'
),

b AS (
    SELECT i.i_item_id,
           i.i_brand,
           t.t_shift
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_brand = 'BrandX'
      AND cd.cd_education_status = 'College'
    UNION
    SELECT i.i_item_id,
           i.i_brand,
           t.t_shift
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_list_price > 100
      AND t.t_shift = 'second'
      AND cd.cd_credit_rating = 'High Risk'
)
SELECT intersected.i_item_id,
       intersected.i_brand,
       intersected.t_shift
FROM (
    SELECT a.i_item_id,
           a.i_brand,
           a.t_shift
    FROM a
    INTERSECT
    SELECT b.i_item_id,
           b.i_brand,
           b.t_shift
    FROM b
) AS intersected
ORDER BY intersected.i_item_id
LIMIT 100
